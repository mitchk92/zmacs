const std = @import("std");
const Core = @import("Core.zig");
const Errors = @import("Errors.zig");
const Color = @import("Color.zig");
const util = @import("util.zig");
pub const Display = struct {
    imp: *anyopaque,
    draw: fn (core: *Core, imp: *anyopaque) Errors.DrawError!void,
    handleUpdate: fn (core: *Core, imp: *anyopaque) Errors.UpdateError!void,
};

pub const DisplayWindow = struct {
    lines: std.ArrayList(DisplayString),
    modeLine: DisplayString,
    pub fn init(alloc: std.mem.Allocator) DisplayWindow {
        return .{
            .lines = std.ArrayList(DisplayString).init(alloc),
            .modeLine = DisplayString.createEmpty(alloc),
        };
    }
    pub fn deinit(self: *DisplayWindow) void {
        for (self.lines.items) |*i| {
            i.deinit();
        }
        self.lines.deinit();
        self.modeLine.deinit();
    }
};

pub const DisplayFrame = struct {
    const FrameType = enum { window, frame };
    const FrameSub = struct {
        fType: FrameType,
        weight: usize,
        id: usize,
    };
};

pub const CursorPos = struct {
    pos: util.Pos,
    window: usize,
};

pub const DrawCommand = struct {
    title: DisplayString,
    cmdLine: DisplayString,
    windows: std.AutoArrayHashMap(usize, DisplayWindow),
    frames: std.AutoArrayHashMap(usize, DisplayFrame),
    cursor: CursorPos,
    pub const topLevelFrame: usize = 0;
    pub fn init(alloc: std.mem.Allocator) DrawCommand {
        var dc = DrawCommand{
            .title = DisplayString.createEmpty(alloc),
            .cmdLine = DisplayString.createEmpty(alloc),
            .windows = std.AutoArrayHashMap(usize, DisplayWindow).init(alloc),
            .frames = std.AutoArrayHashMap(usize, DisplayFrame).init(alloc),
            .cursor = .{ .pos = .{ .row = 1, .col = 10 }, .window = 0 },
        };

        return dc;
    }
    pub fn deinit(self: *DrawCommand) void {
        self.title.deinit();
        self.cmdLine.deinit();
        var iter = self.windows.iterator();
        while (iter.next()) |item| {
            item.value_ptr.deinit();
        }
        self.windows.deinit();
        self.frames.deinit();
    }
};

pub const LinePos = struct {
    line: usize,
    col: usize,
};

pub const MenuItem = struct {};

pub const DisplayScreen = struct {
    title: DisplayString,
    menuBar: std.ArrayList(DisplayString),
    windows: std.ArrayList(DisplayWindow),
    splits: std.ArrayList(DisplaySplit),
    topLevelSplit: usize,
};
