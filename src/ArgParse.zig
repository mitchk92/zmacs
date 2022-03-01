const std = @import("std");

pub const ArgItem = struct {
    name: []const u8,
    parseFunc: fn (args: []const []const u8) usize,
};

pub const ArgResults = struct {
    item: ArgItem,
    args: []const []const u8,
};

pub fn ArgParser(alloc: std.mem.Allocator, args: []const ArgItem) !void {
    var proc_args = try std.process.argsAlloc(alloc);
    defer {
        std.process.argsFree(alloc, proc_args);
    }
    for (proc_args) |pa, idx| {
        if (idx == 0) {
            continue;
        }
        for (args) |arg| {
            if (std.mem.eql(u8, arg.name, pa)) {
                std.log.info("{s}", .{pa});
            }
        }
    }
}
