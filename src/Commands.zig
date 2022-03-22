const std = @import("std");

pub const Context = struct {
    alloc: std.mem.Allocator,
    dir: std.fs.Dir,
};

pub const Arg = union(enum) {
    Uint: usize,
    Int: isize,
    String: []const u8,
};

pub const ArgList = struct {
    args: std.StringHashMap(Arg),
};

pub const CmdFuncError = error{
    FatalError,
};
pub const CmdFunc = union(enum) {
    oneToOne: fn (ctx: Context, args: ArgList, input: Arg) CmdFuncError!Arg,
    oneToMany: fn (ctx: Context, args: ArgList, input: Arg) CmdFuncError![]Arg,
    manyToMany: fn (ctx: Context, args: ArgList, input: []const Arg) CmdFuncError![]Arg,
    manyToOne: fn (ctx: Context, args: ArgList, input: []const Arg) CmdFuncError!Arg,
};

pub const Command = struct {
    name: []const u8,
    func: CmdFunc,
};

pub const commands = [_]Command{
    .{ .name = "ListDir", .func = .{ .oneToMany = listDirFunc } },
};

fn listDirFunc(ctx: Context, args: ArgList, input: Arg) CmdFuncError![]Arg {
    _ = args;
    _ = ctx;
    _ = input;
    return CmdFuncError.FatalError;
}
fn listDirFuncSub(ctx: Context, args: ArgList, input: []const u8) !std.ArrayList([]u8) {
    _ = args;
    const filesOnly = true;
    var arenaAlloc = std.heap.ArenaAllocator.init(ctx.alloc);
    defer arenaAlloc.deinit();
    const alloc = arenaAlloc.allocator();
    var toIter = std.ArrayList([]u8).init(alloc);

    try toIter.append(try alloc.dupe(u8, input));
    var results = std.ArrayList([]u8).init(ctx.alloc);
    errdefer {
        for (results.items) |r| {
            ctx.alloc.free(r);
        }
        results.deinit();
    }

    while (toIter.popOrNull()) |dir| {
        var subDir = try ctx.dir.openDir(dir, .{ .iterate = true });
        defer subDir.close();
        var iter = subDir.iterate();
        while (try iter.next()) |subItem| {
            switch (subItem.kind) {
                .BlockDevice, .CharacterDevice, .NamedPipe, .SymLink, .UnixDomainSocket, .Whiteout, .Door, .EventPort, .Unknown => {
                    if (!filesOnly) try results.append(try ctx.alloc.dupe(u8, subItem.name));
                },
                .File => {
                    try results.append(try ctx.alloc.dupe(u8, subItem.name));
                },
                .Directory => {
                    var dirName = try std.fmt.allocPrint(alloc, "{s}/{s}", .{ dir, subItem.name });
                    try toIter.append(dirName);
                },
            }
        }
    }
    return results;
}

test {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();
    var ctx = Context{
        .alloc = alloc,
        .dir = std.fs.cwd(),
    };

    var args = ArgList{
        .args = std.StringHashMap(Arg).init(alloc),
    };
    defer args.args.deinit();
    var items = try listDirFuncSub(ctx, args, ".");
    for (items.items) |item| {
        std.log.err("File:{s}", .{item});
        alloc.free(item);
    }
    items.deinit();
}
