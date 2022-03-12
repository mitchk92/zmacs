const std = @import("std");

pub const Regex = struct {
    const charSet = struct {
        const ch = union(enum) {
            ptr: []const u8,
            val: struct { vals: [7]u8, len: u8 },
        };
        chars: ch,
        negative: bool,
    };
    pub fn escapedChar(str: []const u8) charSet {
        switch (str[0]) {
            'w' => {
                return .{ .chars = .{ .ptr = word }, .negative = false };
            },
            'W' => {
                return .{ .chars = .{ .ptr = word }, .negative = true };
            },
            'd' => {
                return .{ .chars = .{ .ptr = digit }, .negative = false };
            },
            'D' => {
                return .{ .chars = .{ .ptr = digit }, .negative = true };
            },
            's' => {
                return .{ .chars = .{ .ptr = whitespace }, .negative = false };
            },
            'S' => {
                return .{ .chars = .{ .ptr = whitespace }, .negative = true };
            },
            '+', '*', '?', '^', '$', '\\', '.', '[', ']', '{', '}', '(', ')', '|', '/' => |val| {
                return .{
                    .chars = .{ .val = .{ .vals = [7]u8{ val, 0, 0, 0, 0, 0, 0 }, .len = 1 } },
                    .negative = false,
                };
            },
            'x' => {
                //const int = std.fmt.parseInt(u8, str[1..], 16);
            },
            else => unreachable,
        }
        unreachable;
    }
    const word = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_";
    const digit = "0123456789";
    const whitespace = " \t\n\r";
    alloc: std.mem.Allocator,
    states: std.ArrayList(*State),
    startingStates: std.ArrayList(*State),
    const State = struct {
        alloc: std.mem.Allocator,
        endState: bool,
        transitions: std.ArrayList(*Transition),
        pub fn init(alloc: std.mem.Allocator) State {
            return .{
                .alloc = alloc,
                .endState = false,
                .transitions = std.ArrayList(*Transition).init(alloc),
            };
        }
        pub fn addTransition(self: *State, nextState: *State) !*Transition {
            var tr = try self.alloc.create(Transition);
            tr.* = Transition.init(self.alloc, nextState);
            try self.transitions.append(tr);
            return tr;
        }

        pub fn deinit(self: *State) void {
            for (self.transitions.items) |tr| {
                tr.deinit();
                self.alloc.destroy(tr);
            }
            self.transitions.deinit();
        }
    };
    const Transition = struct {
        const Nextstate = u32;
        const ClassType = enum {
            Whitespace,
            Digit,
            Word,
        };
        const charType = struct {
            chars: u8[23],
            len: u8,
        };
        const rangeType = struct {
            //both inclusive
            low: u8,
            upper: u8,
        };

        const txType = union(enum) {
            chars: [24]u8,
            class: ClassType,
            range: rangeType,
        };
        txt: txType,
        negative: bool,
        nextState: NextState,
        pub fn initClass(nextState: NextState, classType: ClassType, negative: bool) Transition {
            return .{
                .txt = .{ .class = classType },
                .negative = negative,
                .nextSate = nextState,
            };
        }
        pub fn initOld(alloc: std.mem.Allocator, nextState: *State) Transition {
            return .{
                .letters = std.ArrayList(u8).init(alloc),
                .negative = false,
                .nextState = nextState,
            };
        }
        pub fn checkTransition(self: Transition, char: u8) ?*State {
            var match = false;
            switch (self.txt) {
                .chars => |ch| {
                    for (ch.chars[0..ch.len]) |val| {
                        if (val == char) {
                            match = true;
                            break;
                        }
                    }
                },
                .class => |class| {
                    const chars = switch (class) {
                        .Whitespace => whitespace,
                        .Digit => digit,
                        .Word => word,
                    };
                    for (chars) |val| {
                        if (val == char) match = true;
                        break;
                    }
                },
            }
            if (match) {
                return !self.negative;
            } else {
                return self.negative;
            }
        }
        pub fn addString(self: *Transition, str: []const u8) !void {
            try self.letters.appendSlice(str);
        }
        pub fn addCharSet(self: *Transition, set: charSet) !void {
            switch (set.chars) {
                .ptr => |v| try self.addString(v),
                .val => |v| {
                    var count: usize = 0;
                    while (count < v.len) : (count += 1) {
                        try self.addChar(v.vals[count]);
                    }
                },
            }
            self.negative = set.negative;
        }
        pub fn addChar(self: *Transition, ch: u8) !void {
            try self.letters.append(ch);
        }
        pub fn deinit(self: Transition) void {
            self.letters.deinit();
        }
    };
    pub const Result = struct { start: usize, end: usize };
    pub fn init(alloc: std.mem.Allocator, pattern: []const u8) !Regex {
        var states = std.ArrayList(*State).init(alloc);
        errdefer {
            for (states.items) |st| {
                st.deinit();
                alloc.destroy(st);
            }
            states.deinit();
        }
        var startingState = try alloc.create(State);
        startingState.* = State.init(alloc);
        var startingStates = std.ArrayList(*State).init(alloc);
        errdefer startingStates.deinit();
        try startingStates.append(startingState);
        try states.append(startingState);
        var curState = startingState;
        var idx: usize = 0;
        while (idx < pattern.len) {
            var p = pattern[idx];
            switch (p) {
                'a'...'z', 'A'...'Z', '0'...'9' => {
                    var newState = try alloc.create(State);
                    newState.* = State.init(alloc);
                    try states.append(newState);
                    var tr = try curState.addTransition(newState);
                    try tr.addChar(p); //stays
                    curState = newState;
                    idx += 1;
                },
                '[' => {
                    const neg = (pattern[idx + 1] == '^');
                    if (neg) idx += 1;
                    var chars = std.ArrayList(u8).init(alloc);
                    defer chars.deinit();
                    idx += 1;

                    outer: while (idx < pattern.len) : (idx += 1) {
                        const prev_char = pattern[idx - 1];
                        const cur_char = pattern[idx];
                        const next_char = if (idx < pattern.len) pattern[idx] else return error.InvalidPattern;
                        switch (cur_char) {
                            '-' => {
                                if (prev_char == '\\') {
                                    try chars.append(cur_char);
                                    continue :outer;
                                }
                                if (prev_char > next_char) return error.InvalidPattern;
                                var ch = prev_char;
                                while (ch <= next_char) : (ch += 1) {
                                    try chars.append(ch);
                                }
                                idx += 1;
                            },
                            ']' => break :outer,
                            '\\' => {
                                const ec = escapedChar(pattern[idx + 1 ..]);
                                switch (ec.chars) {
                                    .ptr => |v| {
                                        try chars.appendSlice(v);
                                    },
                                    .val => |v| {
                                        var count: usize = 0;
                                        while (count < v.len) : (count += 1) {
                                            try chars.append(v.vals[count]);
                                        }
                                    },
                                }
                                switch (next_char) {
                                    '[', ']', '\\' => {
                                        try chars.append(next_char);
                                        idx += 1;
                                    },
                                    else => unreachable, //TODO work all this out
                                }
                            },
                            else => {
                                if (next_char == '-') continue :outer;
                                try chars.append(next_char);
                            },
                        }
                    }
                    var newState = try alloc.create(State);
                    newState.* = State.init(alloc);
                    try states.append(newState);
                    var tr = try curState.addTransition(newState);
                    //for (chars.items) |ch| {
                    //try tr.addChar(ch); // TODO should be a range
                    //}
                    tr.negative = neg;
                    idx += 1;
                    curState = newState;
                },
                '.' => {
                    var newState = try alloc.create(State);
                    newState.* = State.init(alloc);
                    try states.append(newState);
                    var tr = try curState.addTransition(newState);
                    try tr.addChar('\n');
                    try tr.addChar('\r');
                    tr.negative = true;
                    curState = newState;
                    idx += 1;
                },
                '\\' => {
                    if (idx + 1 >= pattern.len) {
                        return error.InvalidPattern;
                    }
                    var newState = try alloc.create(State);
                    newState.* = State.init(alloc);
                    try states.append(newState);
                    var tr = try curState.addTransition(newState);
                    const ec = escapedChar(pattern[idx + 1 ..]);
                    try tr.addCharSet(ec);
                    std.log.err("addChar [{}]", .{ec});
                    curState = newState;
                    idx += 2;
                },
                else => {
                    std.log.err("Found :{c}", .{p});
                    return error.Unimplemented;
                },
            }
        }
        curState.endState = true;
        return Regex{
            .alloc = alloc,
            .states = states,
            .startingStates = startingStates,
        };
    }
    pub fn printState(self: Regex, writer: anytype) !void {
        try std.fmt.format(writer, "startingStates:[{}]\n", .{self.startingStates.items.len});
        for (self.states.items) |state| {
            try std.fmt.format(writer, "Transitions:[{}]\n", .{state.transitions.items.len});
            for (state.transitions.items) |tr| {
                try std.fmt.format(writer, "[{}][{s}]\n", .{ tr.negative, tr.letters.items });
            }
        }
    }
    pub fn deinit(self: Regex) void {
        for (self.states.items) |item| {
            item.deinit();
            self.alloc.destroy(item);
        }
        self.states.deinit();
        self.startingStates.deinit();
    }

    const ActiveState = struct {
        state: *State,
        start: usize,
    };
    pub fn exec(self: Regex, alloc: std.mem.Allocator, text: []const u8) ![]Result {
        _ = self;
        _ = alloc;
        _ = text;
        var results = std.ArrayList(Result).init(alloc);
        errdefer results.deinit();
        var activeStates = std.ArrayList(ActiveState).init(alloc);
        defer activeStates.deinit();
        var prevActiveStates = std.ArrayList(ActiveState).init(alloc);
        defer prevActiveStates.deinit();

        var as = &activeStates;
        var pas = &prevActiveStates;

        for (text) |ch, idx| {
            for (pas.items) |state| {
                for (state.state.transitions.items) |tr| {
                    if (tr.checkTransition(ch)) |ns| {
                        if (ns.endState) {
                            try results.append(.{ .start = state.start, .end = idx + 1 });
                        } else {
                            try as.append(.{ .state = ns, .start = state.start });
                        }
                    }
                }
            }
            for (self.startingStates.items) |state| {
                for (state.transitions.items) |tr| {
                    if (tr.checkTransition(ch)) |ns| {
                        if (ns.endState) {
                            try results.append(.{ .start = idx, .end = idx });
                        } else {
                            try as.append(.{ .state = ns, .start = idx });
                        }
                    }
                }
            }

            var tmp = as;
            as = pas;
            pas = tmp;
            as.clearRetainingCapacity();
        }
        return results.items;
    }
};

const TestMap = struct {
    pattern: []const u8,
    printPattern: bool = false,
    texts: []const TestText,
};

const TestText = struct {
    text: []const u8,
    expectedResult: []const Regex.Result,
};

test {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var alloc = gpa.allocator();

    const tests = [_]TestMap{
        .{
            .pattern = "Hello",
            .texts = &.{
                .{
                    .text = "Hello",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                    },
                },
                .{
                    .text = "Hello Hello",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                        .{ .start = 6, .end = 11 },
                    },
                },
            },
        },
        .{
            .pattern = "H[ea]llo",
            .texts = &.{
                .{
                    .text = "Hello",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                    },
                },
                .{
                    .text = "Hallo",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                    },
                },
                .{
                    .text = "Hallo Hello",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                        .{ .start = 6, .end = 11 },
                    },
                },
            },
        },
        .{
            .pattern = "H[^bg]llo",
            .texts = &.{
                .{
                    .text = "Hello",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                    },
                },
                .{
                    .text = "Hallo Hbllo",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                    },
                },
                .{
                    .text = "Hallo Hello",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                        .{ .start = 6, .end = 11 },
                    },
                },
            },
        },
        .{
            .pattern = "H[\\w\\W]llo",
            .texts = &.{
                .{
                    .text = "Hello",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                    },
                },
                .{
                    .text = "Hallo Hbllo",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                        .{ .start = 6, .end = 11 },
                    },
                },
                .{
                    .text = "Hallo Hello",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                        .{ .start = 6, .end = 11 },
                    },
                },
            },
        },
        .{
            .pattern = "H.llo",
            .texts = &.{
                .{
                    .text = "Hello",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                    },
                },
                .{
                    .text = "Hallo",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                    },
                },
                .{
                    .text = "Hallo Hello",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                        .{ .start = 6, .end = 11 },
                    },
                },
            },
        },
        .{
            .pattern = "H\\wllo",
            .texts = &.{
                .{
                    .text = "Hello",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                    },
                },
                .{
                    .text = "Hallo",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                    },
                },
                .{
                    .text = "Hallo Hello",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                        .{ .start = 6, .end = 11 },
                    },
                },
            },
        },
        .{
            .pattern = "H\\Wllo",
            .printPattern = true,
            .texts = &.{
                .{
                    .text = "H(llo",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                    },
                },
                .{
                    .text = "H)llo",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                    },
                },
                .{
                    .text = "H llo H\tllo",
                    .expectedResult = &.{
                        .{ .start = 0, .end = 5 },
                        .{ .start = 6, .end = 11 },
                    },
                },
            },
        },
    };
    for (tests) |tc| {
        errdefer {
            std.log.err("Pattern: {s}", .{tc.pattern});
        }
        var reg = try Regex.init(alloc, tc.pattern);
        defer reg.deinit();
        if (tc.printPattern) {
            var output = std.ArrayList(u8).init(alloc);
            defer output.deinit();
            var writer = output.writer();
            try reg.printState(writer);
            std.log.err("{s} => {s}", .{ tc.pattern, output.items });
        }
        for (tc.texts) |text| {
            errdefer std.log.err("Text:{s}", .{text.text});
            var res = try reg.exec(alloc, text.text);
            defer alloc.free(res);
            if (text.expectedResult.len != res.len) {
                for (text.expectedResult) |exp| {
                    std.log.err("exp:{}", .{exp});
                }
                for (res) |fnd| {
                    std.log.err("found:{}", .{fnd});
                }
            }
            try std.testing.expectEqual(text.expectedResult.len, res.len);

            var expected = std.ArrayList(Regex.Result).init(alloc);
            defer expected.deinit();
            try expected.appendSlice(text.expectedResult);
            outer: for (res) |item| {
                for (expected.items) |expItem, idx| {
                    if (expItem.start == item.start and expItem.end == item.end) {
                        _ = expected.swapRemove(idx);
                        continue :outer;
                    }
                }
                std.log.err("Couldn't find {} in expected results", .{item});
                try std.testing.expect(false); // couldnt find item in expected items
            }
            try std.testing.expect(0 == expected.items.len);
        }
    }
}
