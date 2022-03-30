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

pub const DisplayToken = struct {
    str: std.ArrayList(u8),
    face: Color.Face,
    pub fn create(alloc: std.mem.Allocator, str: []const u8, face: Color.Face) !DisplayToken {
        var stringArray = std.ArrayList(u8).init(alloc);
        try stringArray.appendSlice(str);
        return DisplayToken{
            .str = stringArray,
            .face = face,
        };
    }
    pub fn deinit(self: *DisplayToken) void {
        self.str.deinit();
    }
};

pub const DisplayString = struct {
    alloc: std.mem.Allocator,
    tokens: std.ArrayList(DisplayToken),
    pub fn createEmpty(alloc: std.mem.Allocator) DisplayString {
        return .{
            .alloc = alloc,
            .tokens = std.ArrayList(DisplayToken).init(alloc),
        };
    }
    pub fn append(self: *DisplayString, text: []const u8, face: Color.Face) !void {
        var token = try DisplayToken.create(self.alloc, text, face);
        try self.tokens.append(token);
    }
    pub fn deinit(self: *DisplayString) void {
        for (self.tokens.items) |*i| {
            i.deinit();
        }
        self.tokens.deinit();
    }
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
