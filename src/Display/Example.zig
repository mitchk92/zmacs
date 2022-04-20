const std = @import("std");
const Display = @import("DisplayCommands.zig");

pub fn example1(alloc: std.mem.Allocator) !Display.DisplayScreen {
    var screen = Display.DisplayScreen.init(alloc);
    screen.addTitle("Example Screen");
    _ = screen.addMenuItem("File");
    _ = screen.addMenuItem("Edit");
    _ = screen.addMenuItem("Options");
    _ = screen.addMenuItem("Buffers");
    _ = screen.addMenuItem("Tools");
    _ = screen.addMenuItem("Help");
}
