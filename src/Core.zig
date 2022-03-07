const std = @import("std");
const Color = @import("Color.zig");
const console = @import("Display/console.zig");

pub const Core = struct {
    colors: Color.ColorSet,

    pub fn init(alloc: std.mem.Allocator) !Core {
        var c = Core{
            .colors = Color.ColorSet.init(alloc),
        };
        try c.colors.addDefaultColors();
        var disp = console.disp.init();
        const inputfd = disp.getFd();
        return c;
    }

    pub fn deinit(self: *Core) void {
        self.colors.deinit();
    }
};
