const std = @import("std");

pub fn start_server(path: []const u8) !void {
    const addr = std.net.initUnix(path);
    var stream = std.net.StreamServer.init(.{});
    try stream.listen(addr);
    while (true) {
        var conn = strem.accept();
    }
}
