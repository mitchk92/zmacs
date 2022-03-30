const std = @import("std");
const Color = @import("Color.zig");
const console = @import("Display/console.zig");
const Core = @import("Core.zig").Core;
pub const Manager = struct {
    fn getSigFd(sig: i32) !i32 {
        var all_mask: std.os.sigset_t = [_]u32{0} ** 32;
        all_mask[0] |= @as(u32, 1) << (@truncate(u5, @intCast(u32, sig)) - 1);
        _ = std.os.linux.sigprocmask(std.os.SIG.BLOCK, &all_mask, null);
        var sigfd = try std.os.signalfd(-1, &all_mask, 0);
        return sigfd;
    }

    const ActionResult = struct { remove: bool };
    const Action = fn (self: *anyopaque, fd: i32) void;
    const CloseAction = fn (core: *Core, fd: i32) void;
    pub const osevent = union(enum) {
        fd: i32,
        signal: i32,
        timerSingleShot: i64,
        timerrecurring: i64,
    };
    pub const oseventListener = struct {
        fd: osevent,
        action: Action,
        close: ?CloseAction,
        ctx: *anyopaque,
    };
    pub const fdListener = struct {
        fd: i32,
        action: Action,
        close: ?CloseAction,
        ctx: *anyopaque,
    };
    alloc: std.mem.Allocator,
    colors: Color.ColorSet,
    epollFD: i32,
    fdActions: std.ArrayList(fdListener),
    disp: *console.disp,
    core: *Core,
    //eventQueue: std.ArrayList(event),
    pub fn init(alloc: std.mem.Allocator) !Manager {
        var c = Manager{
            .alloc = alloc,
            .colors = Color.ColorSet.init(alloc),
            .epollFD = @truncate(i32, @bitCast(isize, std.os.linux.epoll_create())),
            .fdActions = std.ArrayList(fdListener).init(alloc),
            .disp = try alloc.create(console.disp),
            .core = try alloc.create(Core),
            //.eventQueue = std.ArrayList(event).init(alloc),
        };
        c.core.* = try Core.init(alloc);
        c.disp.* = try console.disp.init(c.core);
        try c.colors.addDefaultColors();
        const inputfd = c.disp.getFd();
        for (inputfd) |fd| {
            try c.addAction(fd.fd, fd.action, fd.close, fd.ctx);
        }
        return c;
    }
    pub fn run(self: *Manager) !void {
        var epoll_events: [10]std.os.linux.epoll_event = undefined;
        while (true) {
            if (try self.core.redraw()) |*redraw_command| {
                try self.disp.drawScreenCmd(redraw_command);
                redraw_command.deinit();
            }
            if (self.disp.quit) {
                return;
            }
            const numevs = @bitCast(isize, std.os.linux.epoll_wait(self.epollFD, epoll_events[0..], epoll_events.len, -1));
            if (numevs < 0) {
                continue;
            }
            const evs = epoll_events[0..@bitCast(usize, numevs)];
            for (evs) |event| {
                for (self.fdActions.items) |item| {
                    if (item.fd == event.data.fd) {
                        item.action(item.ctx, item.fd);
                    }
                }
            }
        }
    }

    pub fn addAction(self: *Manager, event: osevent, action: Action, close: ?CloseAction, ctx: *anyopaque) !void {
        const fd = switch (event) {
            .fd => |f| f,
            .signal => |sig| try getSigFd(sig),
            else => return error.Unimplemented,
        };
        var ev = std.os.linux.epoll_event{
            .events = std.os.linux.EPOLL.IN,
            .data = .{ .fd = fd },
        };
        try std.os.epoll_ctl(
            self.epollFD,
            std.os.linux.EPOLL.CTL_ADD,
            fd,
            &ev,
        );
        try self.fdActions.append(.{ .fd = fd, .action = action, .close = close, .ctx = ctx });
    }

    pub fn deinit(self: *Manager) void {
        self.colors.deinit();
        for (self.fdActions.items) |action| {
            if (action.close) |closefn| {
                closefn(self.core, action.fd);
            }
        }
        self.disp.deinit();
        self.alloc.destroy(self.disp);
        self.core.deinit();
        self.alloc.destroy(self.core);
        self.fdActions.deinit();
        std.os.close(self.epollFD);
    }
};
