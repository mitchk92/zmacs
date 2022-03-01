const std = @import("std");
const argparse = @import("ArgParse.zig");

pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const ap = [_]argparse.ArgItem{
        .{
            .longName = "--run-server",
        },
    };
    try argparse.ArgParser(gpa.allocator(), ap[0..]);
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
