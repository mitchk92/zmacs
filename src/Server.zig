const std = @import("std");

pub fn run(location: []const u8, notify: ?usize) !void {
    std.log.info("{s}:{}", .{ location, notify });
}
