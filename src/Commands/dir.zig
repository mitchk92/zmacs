const std = @import("std");

pub fn listDir(dir: std.fs.Dir, alloc: std.mem.Allocator) !std.ArrayList([]u8) {
    var results = std.ArrayList([]u8).init(alloc);
    errdefer {
        for (results.items) |item| {
            alloc.free(item);
        }
        results.deinit();
    }
    var toIter = std.ArrayList([]u8).init(alloc);
    defer {
        for (toIter.items) |item| {
            alloc.free(item);
        }
        toIter.deinit();
    }
    try toIter.append(try alloc.dupe(u8, "."));

    while (toIter.popOrNull()) |item| {
        defer alloc.free(item);

        var nDir = try dir.openDir(item, .{ .iterate = true });
        defer nDir.close();
        var niter = nDir.iterate();
        while (try niter.next()) |nitem| {
            var name = try std.fmt.allocPrint(alloc, "{s}/{s}", .{ item, nitem.name });
            errdefer alloc.free(name);
            switch (nitem.kind) {
                .Directory => {
                    try toIter.append(name);
                },
                else => {
                    try results.append(name);
                },
            }
        }
    }
    return results;
}
