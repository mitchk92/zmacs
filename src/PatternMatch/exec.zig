const std = @import("std");

pub const Transition = struct {
    nextState: usize, // null is finish state
    t: TransitionType,
    inverse: bool,
    pub fn match(self: Transition, char: u8) bool {
        const match = switch (self.t) {
            .charList => |cl| cl.match(char),
            .charType => |ct| matchType(ct, char),
        };
    }
    fn matchType(ct: CharType, char: u8) bool {
        switch (ct) {
            .Word => "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_",
            .Whitespace => "\t\nv\f\r\x20",
            .DecimalDigit => "0123456789",
            .HexDigit => "0123456789ABCDEFabcdef",
        }
    }

    pub const TransitionType = union(enum) {
        charList: CharList,
        charType: CharType,
    };
    const CharType = enum {
        Word,
        Whitespace,
        DecimalDigit,
        HexDigit,
        NotNewLine,
    };
    const CharList = struct {
        num: u8,
        chars: [23]u8,
        pub fn match(self: CharList, ch: u8) bool {
            for (self.chars[0..num]) |char| {
                if (char == ch) return true;
            }
            return false;
        }
    };
};

pub const State = struct {
    endState: bool,
    transitions: []Transition,
};

pub const Exec = struct {
    initialState: State,
    states: []State,
    alloc: std.mem.Allocator,
    pub fn init(states: []State, initialState: State, alloc: std.mem.Allocator) Exec {
        return .{
            .initialState = initialState,
            .states = states,
            .alloc = alloc,
        };
    }
};
