pub const FileContext = struct {
    pub const FileOpenOpts = struct {};
    alloc: std.mem.Allocator,
    fileContents: []u8,
    path: []const u8,
    writable: bool,
    pub fn init(ctx: *s_ctx, path: []const u8, opts: FileOpenOpts) !FileContext {
        var file = try ctx.rootDir.openFile(path, .{});
        defer file.close();
        var metadata = try file.metadata();
        const size = metadata.size();

        return FileContext{
            .alloc = ctx.alloc,
            .fileContents = file.readToEndAlloc(alloc, size),
            .path = path,
            .writable = !metadata.Permissions.readOnly(),
        };
    }
};

pub const SearchFiles = struct {
    alloc: std.mem.Allocator,
    results: []Result,

    pub fn init(ctx: *s_ctx, files: []const []const u8, searchTerm: []const u8) !SearchFiles {
        var buf: [4096]u8 = undefined;
        for (files) |file_name| {
            var file = ctx.rootDir.openFile(file_name, .{});
            while (true) {
                const len = try file.read(buf);
            }
        }
    }
};
