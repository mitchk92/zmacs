const std = @import("std");
const Manager = @import("Manager.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var alloc = gpa.allocator();

    var manager = try Manager.Manager.init(alloc);
    defer manager.deinit();
    try manager.run();
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
