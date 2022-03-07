const std = @import("std");
const Manager = @import("Manager.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
<<<<<<< HEAD
    const alloc = gpa.allocator();
    var parsed_args = try args.ParseArgs.init(alloc);
    defer parsed_args.deinit();
    std.log.info("{}", .{parsed_args});
=======
    var alloc = gpa.allocator();

    var manager = try Manager.Manager.init(alloc);
    defer manager.deinit();
    try manager.run();
>>>>>>> 9785d51 (more work)
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
