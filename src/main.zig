const std = @import("std");
//const EdCore = @import("EditorCore.zig");
const dir = @import("Commands/dir.zig");
pub fn main() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var results = try dir.listDir(std.fs.cwd(), alloc);
    defer {
        for (results.items) |item| {
            alloc.free(item);
        }
        results.deinit();
    }
    for (results.items) |item| {
        std.log.info("{s}", .{item});
    }

    //var core = EdCore.Core.init(alloc, std.fs.cwd());
    //defer core.deinit();
}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
