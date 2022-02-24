const std = @import("std");

pub const Instance = struct {
    fn fork_and_startup(dir: std.fs.Dir) std.fs.Stat {
        // create cmdline args for creating server
        // {exe} --create_server {[dir].zmacs_socket}
        // fork
        // exec
    }

    pub fn init(rootPath: []const u8) !Instance {
        var dir = if (std.fs.path.isAbsolute(rootPath)) try std.fs.openDirAbsolute(rootPath) else try std.fs.cwd().openDir(rootPath);
        var socket_stat = dir.statFile(".zmacs_socket") catch |err| {
            switch (err) {
                .FileNotFound => fork_and_startup(dir),
                else => return err,
            }
        };
        if (socket_stat) |stat| {
            switch (stat.kind) {
                .UnixDomainSocket => {}, //
                else => return error.InvalidFileFound,
            }
        }
        // check if path exists
        // check if .zmacs_socket exists
        // check if connect to .zmacs_socket
        //

    }
};
