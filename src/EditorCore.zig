const std = @import("std");

pub const Core = struct {
    pub fn init(alloc: std.mem.Allocator, dir: std.fs.Dir) Core {
        return .{
            .alloc = alloc,
            .baseDir = dir,
            .resources = std.ArrayHashMap(usize, *SystemResource).init(alloc),
        };
    }
    alloc: std.mem.Allocator,
    baseDir: std.fs.Dir,
    resources: std.ArrayHashMap(usize, *SystemResource),
};

pub const SystemFile = struct {
    fileName: []const u8,
    handle: ?std.fs.File,
};
pub const SystermResource = struct {
    pub const ResourceType = union(enum) {
        file: SystemFile,
    };
};
