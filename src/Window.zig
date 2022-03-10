const std = @import("std");
const Buffer = @import("Buffer.zig").Buffer;
const util = @import("util.zig");

const CursorSet = struct {
    pub fn init(alloc: std.mem.Allocator) CursorSet {
        return .{
            .cursors = std.ArrayList(util.Pos).init(alloc),
        };
    }
    cursors: std.ArrayList(util.Pos),
};

pub const Window = struct {
    buffer: Buffer,
    cursorSet: CursorSet,

    pub fn init(alloc: std.mem.Allocator, buffer: Buffer) !Window {
        return Window{
            .buffer = buffer,
            .cursorSet = CursorSet.init(alloc),
        };
    }
    pub fn deinit(self: *Window) void {
        self.buffer.deinit();
    }
};
