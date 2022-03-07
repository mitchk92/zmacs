const std = @import("std");

const console = @import("Display/console.zig");

pub fn GetDisplay(alloc: std.mem.Allocator, preferConsole: bool) !Display {
    var cdisp = try alloc.create(console.disp);
    cdisp.* = try console.disp.init();
}
