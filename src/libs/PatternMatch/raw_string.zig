const std = @import("std");
const exec = @import("exec.zig");

pub fn compile(alloc: std.mem.Allocator, str: []const u8) !exec.Exec {
    var e = exec.Exec.init(alloc);
}
