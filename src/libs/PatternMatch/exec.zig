const std = @import("std");

pub const State = struct {
    const RawString = struct {
        pub fn create(str: []const u8) !RawString {
            if (str.len > 23) return error.TooLong;
            var r = RawString{
                .vals = [_]u8{0},
                .len = str.len,
            };
            for (str) |v, i| r.vals[i] = v;
            return r;
        }
        vals: [23]u8,
        len: u8,
    };
    const InnerState = union(enum) {
        raw: RawString,
    };

    state: InnerState,
};

pub const Exec = struct {
    states: std.ArrayList(State),
    pub fn init(alloc: std.mem.Allocator) Exec {
        return .{
            .states = std.ArrayList(State).init(alloc),
        };
    }
};
