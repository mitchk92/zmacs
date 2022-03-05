const std = @import("std");
const MessagePack = @import("MessagePack.zig");

pub const RemoteArg = struct {
    name: []const u8,
    argType: MessagePack.ValueFormat,
    nullable: bool,
};

pub const RemoteCall = struct {
    name: []const u8,
    args: []const RemoteArg,
    result: RemoteArg,
};

pub const ServerFunctions = [_]RemoteCall{
    RemoteCall{
        .name = "init",
        .args = &[_]RemoteArg{
            .{ .name = "" },
        },
    },
};

pub fn fmtMessage(func: []const u8, args: []MessagePack.Value) u64 {
    _ = func;
    _ = args;
    return 0;
}
