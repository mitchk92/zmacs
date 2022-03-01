const std = @import("std");

pub const ArgVal = union(enum) {
    Int: void,
    String: void,
    Array: []const ArgVal,
    Map: []const Argument,
};

pub const Argument = struct {
    name: []const u8,
    val: ArgVal,
};

pub const Action = struct {
    name: []const u8,
    docs: []const u8,
    args: []const Argument,
    result: ArgVal,
};

pub const actions = [_]Action{
    .{
        .name = "OpenFile",
        .docs = "Opens a file and returns an id for it",
        .args = &.{
            .{
                .name = "FileName",
                .val = .String,
            },
        },
        .result = .Int,
    },
    .{
        .name = "RegexSearch",
        .docs = "Searcha a file with a regex returing line/col of each match",
        .args = &.{
            .{
                .name = "FileRef",
                .val = .Int,
            },
            .{
                .name = "Regex",
                .val = .String,
            },
        },
        .result = .{
            .Array = &.{
                .{
                    .Map = &.{
                        .{
                            .name = "Line",
                            .val = .Int,
                        },
                        .{
                            .name = "Col",
                            .val = .Int,
                        },
                    },
                },
            },
        },
    },
};

test {
    _ = actions;
}
