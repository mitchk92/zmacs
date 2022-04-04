const std = @import("std");
const exec = @import("exec.zig");

pub fn compile(str: []const u8, alloc: std.mem.Allocator) !exec.Exec {
    var current_string = std.ArrayList(u8).init(alloc);
    defer current_string.deinit();

    for (str) |ch| {
        switch (ch) {
            '?' => |val| {
                if (inBrac) {
                    try current_string.append(val);
                } else {
                    // add wildcard
                }
            },
            '*' => |val| {
                if (inBrac) {
                    try current_string.append(val);
                } else {
                    // add wildcard
                }
            },
            '[' => |val| {
                if (inBrac) {
                    try current_string.append(val);
                } else {
                    // add wildcard
                }
            },
        }
    }
}
