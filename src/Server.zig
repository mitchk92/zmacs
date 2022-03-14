const std = @import("std");

pub const ServerSocket = ".zmacs_server";

pub fn runServer(alloc: std.mem.Allocator) !void {
    _ = alloc;
    var dir = std.fs.cwd();
    dir.deleteFile(ServerSocket) catch |err| {
        switch (err) {
            error.FileNotFound => {},
            else => return err,
        }
    };
    defer dir.deleteFile(ServerSocket) catch {};
    var server = std.net.StreamServer.init(.{});
    try server.listen(try std.net.Address.initUnix(ServerSocket));
    var conn = try server.accept();
    defer conn.stream.close();

    var buf: [4096]u8 = undefined;
    const len = try conn.stream.read(buf[0..]);
    std.log.info("read:[{s}]", .{buf[0..len]});
}

const ClientConnection = struct {
    stream: std.net.Stream,
};
