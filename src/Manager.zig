const std = @import("std");
const Color = @import("Color.zig");
const console = @import("Display/console.zig");
const Core = @import("Core.zig").Core;
pub const Manager = struct {
    const ActionResult = struct { remove: bool };
    const Action = fn (self: *anyopaque, fd: usize) void;
    const CloseAction = fn (core: *Core, fd: usize) void;
    const fdListener = struct {
        fd: usize,
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
        std.log.info("init core \r", .{});
        c.disp.* = try console.disp.init();
        c.core.* = Core.init(alloc);
        std.log.info("init core disp\r", .{});
        try c.colors.addDefaultColors();
        const inputfd = c.disp.getFd();
        try c.addAction(inputfd, console.disp.update, null, c.disp);
        std.log.info("init core\r", .{});
        return c;
    }
    pub fn run(self: *Manager) !void {
        var epoll_events: [10]std.os.linux.epoll_event = undefined;
        while (true) {
            std.log.info("Running...\r", .{});
            if (self.disp.quit) {
                std.log.info("quiting...\r", .{});
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

    pub fn addAction(self: *Manager, fd: usize, action: Action, close: ?CloseAction, ctx: *anyopaque) !void {
        var ev = std.os.linux.epoll_event{
            .events = std.os.linux.EPOLL.IN,
            .data = .{
                .fd = @truncate(i32, @bitCast(isize, fd)),
            },
        };
        try std.os.epoll_ctl(
            self.epollFD,
            std.os.linux.EPOLL.CTL_ADD,
            @truncate(i32, @bitCast(isize, fd)),
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
        self.fdActions.deinit();
        std.os.close(self.epollFD);
    }
};
