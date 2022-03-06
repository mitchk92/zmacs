const std = @import("std");
const Core = @import("Core.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var alloc = gpa.allocator();

    var core = try Core.Core.init(alloc);
    defer core.deinit();
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
