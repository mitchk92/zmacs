const std = @import("std");
const arg = @import("ArgParse.zig");
const server = @import("Server.zig");
const messagePack = @import("MessagePack.zig");
const clientServer = @import("ClientServer.zig");

pub fn main() anyerror!void {
    _ = clientServer.fmtMessage("test", &.{});
    try messagePack.tests();
    if (true) return;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    var opts = try arg.parse(alloc);
    defer {
        opts.deinit();
    }
    if (opts.server_mode) |sm| {
        try server.run(sm, opts.server_notify_pid);
        return;
    }
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
