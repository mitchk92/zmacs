const std = @import("std");
const Display = @import("../Display.zig");
const Manager = @import("../Manager.zig");
const Core = @import("../Core.zig").Core;
const Util = @import("../util.zig");
const Color = @import("../Color.zig");
pub const disp = struct {
    orig: std.os.termios,
    size: Util.Pos,
    quit: bool,
    core: *Core,
    pub fn getFd(self: *disp) [2]Manager.Manager.oseventListener {
        return [2]Manager.Manager.oseventListener{
            .{
                .fd = .{ .fd = std.os.STDIN_FILENO },
                .action = update,
                .close = null,
                .ctx = @ptrCast(*anyopaque, self),
            },
            .{
                .fd = .{ .signal = std.os.SIG.WINCH },
                .action = updateScreenSize,
                .close = null,
                .ctx = @ptrCast(*anyopaque, self),
            },
        };
    }
    pub fn init(core: *Core) !disp {
        const in_fd = std.os.STDIN_FILENO;
        const out_fd = std.os.STDOUT_FILENO;
        if (!std.os.isatty(in_fd)) {
            return error.InvalidWindow;
        }

        const orig = try std.os.tcgetattr(out_fd);

        var raw = orig; //* modify the original mode */

        //* input modes: no break, no CR to NL, no parity check, no strip char,
        //* no start/stop output control. */
        raw.iflag &= ~(std.os.system.BRKINT | std.os.system.ICRNL | std.os.system.INPCK | std.os.system.ISTRIP | std.os.system.IXON);
        //* output modes - disable post processing */
        raw.oflag &= ~(std.os.system.OPOST);
        //* control modes - set 8 bit chars */
        raw.cflag |= (std.os.system.CS8);
        //* local modes - choing off, canonical off, no extended functions,
        //* no signal chars (^Z,^C) */
        raw.lflag &= ~(std.os.system.ECHO | std.os.system.ICANON | std.os.system.IEXTEN | std.os.system.ISIG);
        //* control chars - set return condition: min number of bytes and timer. */
        //raw.cc[6] = 0; //* Return each byte, or zero for timeout. */ //VMIN
        _ = std.os.write(std.os.STDOUT_FILENO, "\x1b[?1049h") catch |err| {
            std.log.err("Err{}", .{err});
            return err;
        };
        //* put terminal in raw mode after flushing */
        try std.os.tcsetattr(in_fd, .FLUSH, raw);
        var d = disp{
            .orig = orig,
            .size = .{ .row = 0, .col = 0 },
            .quit = false,
            .core = core,
        };
        d.updateScreenSize(0);
        return d;
    }
    pub fn update(self_ptr: *anyopaque, _: i32) void {
        var self = @ptrCast(*align(1) disp, self_ptr);
        var buf: [4096]u8 = undefined;
        const len = (std.os.read(std.os.STDIN_FILENO, buf[0..]) catch return);
        for (buf[0..len]) |char| {
            if (char == 'q') self.quit = true;
        }
    }
    pub fn updateScreenSize(self_ptr: *anyopaque, fd: i32) void {
        var self = @ptrCast(*align(1) disp, self_ptr);
        var ws: std.os.system.winsize = undefined;
        var buf: [400]u8 = undefined;
        if (fd != 0) {
            _ = std.os.read(fd, buf[0..]) catch 0;
        }
        if (std.os.system.ioctl(
            1,
            std.os.system.T.IOCGWINSZ,
            @ptrToInt(&ws),
        ) == 0) {
            self.size = .{
                .row = ws.ws_row,
                .col = ws.ws_col,
            };
        } else {
            @panic("Don't know how to do without ioctl for winsize");
        }
    }

    pub fn drawScreenCmd(self: disp, cmds: *const Display.DrawCommand) !void {
        var writer = std.io.getStdOut().writer();
        var drawBuffer = std.ArrayList(std.ArrayList(u8)).init(self.core.alloc);
        defer {
            for (drawBuffer.items) |item| {
                item.deinit();
            }
            drawBuffer.deinit();
        }
        var arena = std.heap.ArenaAllocator.init(self.core.alloc);
        defer arena.deinit();
        var arenaAlloc = arena.allocator();
        //const framePos = .{ .pos = .{ .row = 1, .col = 0 }, .size = .{ .row = self.size.row - 2, .col = self.size.col - 2 } };
        var lineBuffer = std.ArrayList(u8).init(self.core.alloc);
        _ = try formatString(cmds.title, &lineBuffer, arenaAlloc);
        try drawBuffer.append(lineBuffer);
        lineBuffer.clearRetainingCapacity();
        _ = try std.os.write(std.os.STDOUT_FILENO, "\x1b[?25l\x1b[H\x1b[2J"); // hide cursor \x1b[?25l,go to base \x1b[H
        for (drawBuffer.items) |line| {
            _ = try std.os.write(std.os.STDOUT_FILENO, line.items);
            _ = try std.os.write(std.os.STDOUT_FILENO, "\r\n");
        }

        try std.fmt.format(writer, "\x1b[{};{}H", .{ cmds.cursor.pos.row, cmds.cursor.pos.col });
        _ = try std.os.write(std.os.STDOUT_FILENO, "\x1b[?25h");
    }

    fn formatString(string: Display.DisplayString, buffer: *std.ArrayList(u8), alloc: std.mem.Allocator) !usize {
        var numPrint: usize = 0;
        for (string.tokens.items) |token| {
            var print = std.ArrayList(u8).init(alloc);
            defer print.deinit();
            try std.fmt.format(print.writer(), "{s}", .{std.fmt.fmtSliceEscapeUpper(token.str.items)});
            numPrint += print.items.len;
            try std.fmt.format(buffer.writer(), "\x1b[38;2;{};{};{}m\x1b[48;2;{};{};{}m{s}{s}{s}{s}{s}{s}\x1b[0m", .{
                token.face.fg.red,
                token.face.fg.green,
                token.face.fg.blue,
                token.face.bg.red,
                token.face.bg.green,
                token.face.bg.blue,
                Color.Face.boldVal[if (token.face.bold) 0 else 1],
                Color.Face.italicVal[if (token.face.italic) 0 else 1],
                Color.Face.underlineVal[if (token.face.underline) 0 else 1],
                Color.Face.strikeVal[if (token.face.strike) 0 else 1],
                Color.Face.overlineVal[if (token.face.overline) 0 else 1],
                print.items,
            });
        }
        return numPrint;
    }
    pub fn drawScreen(self: disp) !void {
        _ = self;
        _ = try std.os.write(std.os.STDOUT_FILENO, "\x1b[?25l\x1b[H\x1b[2J"); // hide cursor \x1b[?25l,go to base \x1b[H

        var stdoutWriter = std.io.getStdOut().writer();
        var frame = self.core.frames.items[0];
        var window = frame.windows.items[0];
        var buffer = window.buffer;
        //var buffer: [1000]u8 = undefined;
        //var fba = std.heap.FixedBufferAllocator.init(&buffer);

        //const allocator = fba.allocator();
        var row: usize = 1;
        var lineNum: usize = 0;
        while (row < self.size.row - 1) : (row += 1) {
            defer lineNum += 1;
            //var col: usize = 0;
            if (lineNum < buffer.lines.items.len) {
                var line = buffer.lines.items[lineNum].items;
                try std.fmt.format(stdoutWriter, "{:2}{s}", .{ lineNum + 1, std.fmt.fmtSliceEscapeLower(line) });
            } else {
                try std.fmt.format(stdoutWriter, "~", .{});
            }
            //stdoutWriter.writeN

            if (row + 2 != self.size.row) {
                _ = try stdoutWriter.write("\r\n");
            }
        }
        _ = try std.os.write(std.os.STDOUT_FILENO, "\x1b[?25h");
    }

    pub fn deinit(self: disp) void {
        _ = std.os.write(std.os.STDOUT_FILENO, "\x1b[?1049l") catch {};
        std.os.tcsetattr(std.os.STDIN_FILENO, .FLUSH, self.orig) catch {};
    }
    pub fn getDisplay(self: *disp) Display.Display {
        return .{
            .imp = self,
            .draw = drawScreen,
            .handleUpdate = update,
        };
    }
};
