const std = @import("std");

const ParseState = enum {
    default,
};

pub const ParseArgs = struct {
    alloc: std.mem.Allocator,
    files: std.ArrayList([]u8),

    pub fn init(alloc: std.mem.Allocator) !ParseArgs {
        var args = try std.process.argsWithAllocator(alloc);
        defer args.deinit();
        var result = ParseArgs{
            .alloc = alloc,
            .files = std.ArrayList([]u8).init(alloc),
        };
        var state = ParseState.default;
        _ = args.next(); // skip bin name
        while (args.next()) |arg| {
            switch (state) {
                .default => {
                    try result.files.append(try alloc.dupe(u8, arg));
                },
            }
        }
        return result;
    }
    pub fn format(value: ParseArgs, comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
        try std.fmt.format(writer, "Files: [", .{});
        var prev = false;
        for (value.files.items) |file| {
            if (prev) try std.fmt.format(writer, ", ", .{});
            prev = true;
            try std.fmt.format(writer, "{s}", .{file});
        }
        try std.fmt.format(writer, "]\n", .{});
    }
    pub fn deinit(self: ParseArgs) void {
        for (self.files.items) |file| {
            self.alloc.free(file);
        }
        self.files.deinit();
    }
};
