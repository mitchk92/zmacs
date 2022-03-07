const std = @import("std");
//const zmacs = @import("zmacs.zig");

pub fn getSigFd() !i32 {
    var all_mask: std.os.sigset_t = [_]u32{0} ** 32;
    all_mask[0] |= 1 << (std.os.SIG.WINCH - 1);
    _ = std.os.linux.sigprocmask(std.os.SIG.BLOCK, &all_mask, null);
    var sigfd = try std.os.signalfd(-1, &all_mask, 0);
    return sigfd;
}

const disp = struct {
    orig: std.os.termios,
    winCols: usize,
    winRows: usize,
    pub fn getFd(_: disp) isize {
        return std.os.STDIN_FILENO;
    }
    pub fn init() !disp {
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
        _ = try std.os.write(std.os.STDOUT_FILENO, "\x1b[?1049h");
        //* put terminal in raw mode after flushing */
        try std.os.tcsetattr(in_fd, .FLUSH, raw);
        var d = disp{
            .orig = orig,
            .winCols = 0,
            .winRows = 0,
        };
        d.updateScreenSize();
        return d;
    }
    pub fn updateScreenSize(self: *disp) void {
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
    pub fn drawScreen(self: disp) !void {
        _ = self;
        _ = try std.os.write(std.os.STDOUT_FILENO, "\x1b[?25l\x1b[H"); // hide cursor \x1b[?25l,go to base \x1b[H

        var stdoutWriter = std.io.getStdOut().writer();

        var buffer: [1000]u8 = undefined;
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
    }

    pub fn deinit(self: disp) void {
        _ = std.os.write(std.os.STDOUT_FILENO, "\x1b[?1049l") catch {};
        std.os.tcsetattr(std.os.STDIN_FILENO, .FLUSH, self.orig) catch {};
    }
};

pub fn run() !void {
    const epoll_pid = @truncate(i32, @bitCast(isize, std.os.linux.epoll_create()));
    const sigfd = try getSigFd();

    var d = try disp.init();
    defer d.deinit();
    var ev = std.os.linux.epoll_event{
        .events = std.os.linux.EPOLL.IN,
        .data = .{
            .fd = sigfd,
        },
    };

    try std.os.epoll_ctl(
        epoll_pid,
        std.os.linux.EPOLL.CTL_ADD,
        sigfd,
        &ev,
    );
    var ev2 = std.os.linux.epoll_event{
        .events = std.os.linux.EPOLL.IN,
        .data = .{
            .fd = std.os.STDIN_FILENO,
        },
    };
    try std.os.epoll_ctl(
        epoll_pid,
        std.os.linux.EPOLL.CTL_ADD,
        std.os.STDIN_FILENO,
        &ev2,
    );

    var epoll_events: [100]std.os.linux.epoll_event = undefined;
    var buffer: [4096]u8 = undefined;
    while (true) {
        try d.drawScreen();
        var numevs = @bitCast(isize, std.os.linux.epoll_wait(epoll_pid, epoll_events[0..], epoll_events.len, -1));
        if (numevs < 0) {
            continue;
        }
        var evs = epoll_events[0..@bitCast(usize, numevs)];
        for (evs) |event| {
            if (event.data.fd == std.os.STDIN_FILENO) {
                const len = try std.os.read(std.os.STDIN_FILENO, buffer[0..]);
                for (buffer[0..len]) |ch| {
                    if (ch == 'q') return;
                }
            } else if (event.data.fd == sigfd) {
                d.updateScreenSize();
                _ = try std.os.read(sigfd, buffer[0..]);
            }
        }
    }

    const pid = std.os.linux.getpid();

    std.log.info("PID:{}", .{pid});
}
