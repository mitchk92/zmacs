const std = @import("std");
const Window = @import("Window.zig").Window;
const Buffer = @import("Buffer.zig").Buffer;
const FrameDisplay = union(enum) {
    split: *FrameSplit,
    window: *Window,
};

const FrameSplit = struct {
    a: FrameDisplay,
    b: FrameDisplay,
    a_weight: usize,
    b_wieght: usize,
    direction: Direction,
    const Direction = enum { Vertical, Horizontal };
};

pub const Frame = struct {
    alloc: std.mem.Allocator,
    split: FrameDisplay,
    windows: std.ArrayList(*Window),
    pub fn init(alloc: std.mem.Allocator, buff: Buffer) !Frame {
        var wind = try alloc.create(Window);
        wind.* = try Window.init(alloc, buff);
        var windows = std.ArrayList(*Window).init(alloc);
        try windows.append(wind);
        return Frame{
            .alloc = alloc,
            .split = .{ .window = wind },
            .windows = windows,
        };
    }
    pub fn deinit(self: Frame) void {
        for (self.windows.items) |wind| {
            wind.deinit();
            self.alloc.destroy(wind);
        }
        self.windows.deinit();
    }
};
