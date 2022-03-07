const std = @import("std");
const Color = @import("Color.zig");
const Display = @import("Display.zig");

pub const Core = struct {
    pub fn init(alloc: std.mem.Allocator) Core {
        return .{
            .alloc = alloc,
        };
    }
    alloc: std.mem.Allocator,
    //colors: Color.ColorSet,
    //display: Display,
};
