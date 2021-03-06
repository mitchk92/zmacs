const std = @import("std");
const Color = @import("Color.zig");
const Display = @import("Display.zig");
const Frame = @import("Frame.zig");
const Buffer = @import("Buffer.zig");
const FileAccess = @import("FileAccess.zig");

pub const Core = struct {
    pub fn init(alloc: std.mem.Allocator) !Core {
        var core = Core{
            .alloc = alloc,
            .frames = std.ArrayList(Frame.Frame).init(alloc),
            .dir = std.fs.cwd(),
            .colors = Color.ColorSet.init(alloc),
        };

        var buf = try core.openFile("build.zig");

        try core.frames.append(try Frame.Frame.init(alloc, try Buffer.Buffer.OpenFile(alloc, buf)));
        return core;
    }
    pub fn deinit(self: *Core) void {
        for (self.frames.items) |frame| {
            frame.deinit();
        }
        self.frames.deinit();
    }
    pub fn openFile(self: Core, filename: []const u8) !FileAccess.FileAccess {
        var file = try self.dir.openFile(filename, .{});
        defer file.close();
        var bytes = try file.readToEndAlloc(self.alloc, 10000000);
        errdefer self.alloc.free(bytes);
        return FileAccess.FileAccess{
            .alloc = self.alloc,
            .fileName = try self.alloc.dupe(u8, filename),
            .data = bytes,
        };
    }
    pub fn redraw(self: *Core) !?Display.DrawCommand {
        var cmd = Display.DrawCommand.init(self.alloc);
        try cmd.title.append("Test Name", self.colors.getFace("default-bold") orelse self.colors.placeHoldFace());
        return cmd;
    }
    alloc: std.mem.Allocator,
    frames: std.ArrayList(Frame.Frame),
    dir: std.fs.Dir,

    colors: Color.ColorSet,
};
