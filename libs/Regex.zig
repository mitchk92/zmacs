const std = @import("std");

pub const Regex = struct {
    alloc: std.mem.Allocator,
    pub const Result = struct { start: usize, end: usize };
    pub fn init(alloc: std.mem.Allocator, pattern: []const u8) !Regex {
        return Regex{
            .alloc = alloc,
            .pattern = try alloc.dupe(u8, pattern),
        };
    }
    pub fn deinit(self: Regex) void {
        self.alloc.free(self.pattern);
    }

    pub fn exec(self: Regex, alloc: std.mem.Allocator, text: []const u8) ![]Result {
        _ = self;
        _ = alloc;
        _ = text;
        var results = std.ArrayList(Result).init(alloc);
        errdefer results.deinit();
        for (text) |ch, idx| {}
        return error.NotImplemented;
    }
};

const TestMap = struct {
    pattern: []const u8,
    texts: []const TestText,
};

const TestText = struct {
    text: []const u8,
    expectedResult: []const Regex.Result,
};

test {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var alloc = gpa.allocator();

    const tests = [_]TestMap{
        .{
            .pattern = "Hello",
            .texts = &.{.{
                .text = "Hello",
                .expectedResult = &.{
                    .{ .start = 0, .end = 5 },
                },
            }},
        },
    };
    for (tests) |tc| {
        var reg = try Regex.init(alloc, tc.pattern);
        defer reg.deinit();
        for (tc.texts) |text| {
            var res = try reg.exec(alloc, text.text);
            defer alloc.free(res);
            try std.testing.expectEqual(res.len, text.expectedResult.len);
        }
    }
}
