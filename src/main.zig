const std = @import("std");
const Server = @import("Server.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var serverMode = false;

    var sysargs = try std.process.argsWithAllocator(alloc);
    while (sysargs.next()) |nxt| {
        if (std.mem.startsWith(u8, nxt, "--")) {
            if (std.mem.eql(u8, nxt[2..], "server")) serverMode = true;
            std.log.info("{s}", .{nxt});
        }
    }
    if (serverMode) Server.runServer();
    std.log.info("All your codebase are belong to us.", .{});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
