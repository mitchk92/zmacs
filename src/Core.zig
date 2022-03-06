const std = @import("std");
const Color = @import("Color.zig");

pub const Core = struct {
    colors: Color.ColorSet,

    pub fn init(alloc: std.mem.Allocator) !Core {
        var c = Core{
            .colors = Color.ColorSet.init(alloc),
        };
        try c.colors.addDefaultColors();
        c.colors.printAllColors();
        return c;
    }
    pub fn deinit(self: *Core) void {
        self.colors.deinit();
    }
};
