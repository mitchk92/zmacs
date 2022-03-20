const std = @import("std");
const Core = @import("Core.zig");
const Errors = @import("Errors.zig");

pub const Display = struct {
    imp: *anyopaque,
    draw: fn (core: *Core, imp: *anyopaque) Errors.DrawError!void,
    handleUpdate: fn (core: *Core, imp: *anyopaque) Errors.UpdateError!void,
};

pub const DrawCommand = struct {
    title: DisplayLine,
    cmdLine: DisplayLine,
    windows: DisplayWindow,
};
