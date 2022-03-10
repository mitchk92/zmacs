const std = @import("std");
const FileAccess = @import("FileAccess.zig");

pub const Buffer = struct {
    alloc: std.mem.Allocator,
    lines: std.ArrayList(std.ArrayList(u8)),
    file: ?FileAccess.FileAccess = null,
    pub fn CreateEmpty(alloc: std.mem.Allocator) Buffer {
        return Buffer{
            .alloc = alloc,
            .lines = std.ArrayList(std.ArrayList(u8)).init(alloc),
        };
    }
    pub fn OpenFile(alloc: std.mem.Allocator, file: FileAccess.FileAccess) !Buffer {
        var lines = std.ArrayList(std.ArrayList(u8)).init(alloc);
        errdefer {
            for (lines.items) |line| {
                line.deinit();
            }
        }
        var split = std.mem.split(u8, file.data, "\n");
        while (split.next()) |fileline| {
            var line = std.ArrayList(u8).init(alloc);
            try line.appendSlice(fileline);
            try lines.append(line);
        }
        return Buffer{
            .alloc = alloc,
            .lines = lines,
            .file = file,
        };
    }
    pub fn deinit(self: *Buffer) void {
        for (self.lines.items) |line| {
            line.deinit();
        }
        self.lines.deinit();
        if (self.file) |f| {
            f.deinit();
        }
    }
};
