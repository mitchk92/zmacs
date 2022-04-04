const std = @import("std");
const String = @import("../String.zig");

const State = enum {};

pub fn Compile(text: []const u8, alloc: std.mem.Allocator) !void {
    var iter = String.utf8iter(text);
    while (try iter.next()) |val| {
        switch (val) {
            else => {
                std.log.err("CH:{c}", .{@truncate(u8, val)});
            },
        }
    }
}

const TestMap = struct {
    pattern: []const u8,
    texts: []const TestText,
};

const Result = struct {
    begin: usize,
    end: usize,
};

const TestText = struct {
    text: []const u8,
    expectedResult: []const Result,
};

test {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var alloc = gpa.allocator();
    try Compile("....", alloc);
    try Compile("(eg[A-Z(])", alloc);
}
