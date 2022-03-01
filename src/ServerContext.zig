const std = @import("std");

pub const ServerContext = struct {
    alloc: std.mem.Allocator,
    rootDir: std.fs.Dir,
};
