const std = @import("std");
const Core = @import("Core.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    var parsed_args = try args.ParseArgs.init(alloc);
    defer parsed_args.deinit();
    std.log.info("{}", .{parsed_args});
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
