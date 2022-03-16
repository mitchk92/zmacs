const Frame = @import("Frame.zig");
const Color = @import("Color.zig").Face;
const Core = @import("Core.zig").Core;
fn setColor(writer: anytype, face: Face) !void {
    try std.fmt.format(writer, "\x1b[38;2;{};{};{}m\x1b[48;2;{};{};{}m", .{
        face.fg.red,
        face.fg.green,
        face.fg.blue,
        face.bg.red,
        face.bg.green,
        face.bg.blue,
    });
}

pub const TerminalDisplay = struct {
    core: *Core,
    orig: std.os.termios,
    winCols: usize,
    winRows: usize,
    pub fn init(core: *Core) TerminalDisplay {
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
        _ = try std.os.write(out_fd, "\x1b[?1049h");
        //* put terminal in raw mode after flushing */
        try std.os.tcsetattr(in_fd, .FLUSH, raw);
        var d = TerminalDisplay{
            .orig = orig,
            .winCols = 0,
            .winRows = 0,
        };
        d.updateScreenSize();
        return d;
    }
    fn updateScreenSize(self: *disp) void {
        var ws: std.os.system.winsize = undefined;
        if (std.os.system.ioctl(
            1,
            std.os.system.T.IOCGWINSZ,
            @ptrToInt(&ws),
        ) == 0) {
            self.winCols = ws.ws_col;
            self.winRows = ws.ws_row;
        } else {
            @panic("Don't know how to do without ioctl for winsize");
        }
    }
    pub fn draw(
        self: *TerminalDisplay,
    ) void {
        _ = try std.os.write(std.os.STDOUT_FILENO, "\x1b[?25l\x1b[H"); // hide cursor \x1b[?25l,go to base \x1b[H

        var stdoutWriter = std.io.getStdOut().writer();
        var buffer: [4096]u8 = undefined;
        var fba = std.heap.FixedBufferAllocator.init(&buffer);

        const allocator = fba.allocator();
        var row: usize = 0;
        while (row < self.winRows) : (row += 1) {
            var arr = std.ArrayList(u8).init(allocator);
            var lineWriter = arr.writer();
            if (row == 0) {
                try lineWriter.writeByteNTimes('#', self.winCols);
                _ = try lineWriter.write("\r\n");
            } else if (row == self.winRows - 1) {
                try lineWriter.writeByteNTimes('#', self.winCols);
            } else {
                var col: usize = 0;

                try std.fmt.format(lineWriter, "{:3}", .{row});

                _ = try lineWriter.write("\r\n");
                while (col < self.winCols - 1) : (col += 1) {}
            }
            _ = try stdoutWriter.write(arr.items);
        }
        _ = try std.os.write(std.os.STDOUT_FILENO, "\x1b[?25h");
        //std.f
    }
    fn drawMenuLine(self: *TerminalDisplay, writer: anytype) usize {
        const tmpTitles = &.{ "File", "Edit", "Options", "Buffers" };
    }
    fn drawCommandLine(self: *TerminalDisplay) void {}
};
