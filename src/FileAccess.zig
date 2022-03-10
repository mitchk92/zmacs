const std = @import("std");

pub const FileAccess = struct {
    alloc: std.mem.Allocator,
    fileName: []u8,
    data: []u8,
    pub fn deinit(self: FileAccess) void {
        self.alloc.free(self.fileName);
        self.alloc.free(self.data);
    }
};
