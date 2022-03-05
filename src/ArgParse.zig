const std = @import("std");

pub const Options = struct {
    pub fn deinit(self: *Options) void {
        if (self.server_mode) |sm| {
            self.alloc.free(sm);
        }
    }
    alloc: std.mem.Allocator,
    server_mode: ?[]u8 = null,
    server_notify_pid: ?usize = null,
};

pub fn parse(alloc: std.mem.Allocator) !Options {
    var opts = Options{
        .alloc = alloc,
    };

    var args = try std.process.argsAlloc(alloc);
    defer std.process.argsFree(alloc, args);
    for (args[1..]) |arg| {
        if (std.mem.startsWith(u8, arg, "--server-init")) {
            var iter = std.mem.split(u8, arg, "=");
            _ = iter.next();
            opts.server_mode = try alloc.dupe(u8, iter.rest());
        } else if (std.mem.startsWith(u8, arg, "--server_start_notify")) {
            var iter = std.mem.split(u8, arg, "=");
            _ = iter.next();
            opts.server_notify_pid = try std.fmt.parseInt(usize, iter.rest(), 10);
        }
    }
    return opts;
}
