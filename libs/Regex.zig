const std = @import("std");

pub const Regex = struct {
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
        letters: std.ArrayList(u8),
        negative: bool,
        nextState: *State,
        pub fn init(alloc: std.mem.Allocator, nextState: *State) Transition {
            return .{
                .letters = std.ArrayList(u8).init(alloc),
                .negative = false,
                .nextState = nextState,
            };
        }
        pub fn checkTransition(self: Transition, ch: u8) ?*State {
            for (self.letters.items) |letter| {
                if (letter == ch) {
                    if (self.negative) {
                        return null;
                    } else {
                        return self.nextState;
                    }
                }
            }
            if (self.negative) {
                return self.nextState;
            } else {
                return null;
            }
        }
        pub fn addString(self: *Transition, str: []const u8) !void {
            try self.letters.appendSlice(str);
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
                    try tr.addChar(p);
                    curState = newState;
                    idx += 1;
                },
                '[' => {
                    const neg = (pattern[idx + 1] == '^');
                    if (neg) idx += 1;
                    var chars = std.ArrayList(u8).init(alloc);
                    defer chars.deinit();
                    var found: ?usize = null;
                    idx += 1;
                    for (pattern[idx..]) |ch, i| {
                        if (ch == ']') {
                            found = i;
                            break;
                        } else if (ch == '-') {
                            var begin = pattern[idx];
                            const end = pattern[idx + i];
                            chars.clearRetainingCapacity();
                            while (begin < end) : (begin += 1) {
                                try chars.append(begin);
                            }
                        } else {
                            try chars.append(ch);
                        }
                    }
                    if (found) |i| {
                        var newState = try alloc.create(State);
                        newState.* = State.init(alloc);
                        try states.append(newState);
                        var tr = try curState.addTransition(newState);
                        for (chars.items) |ch| {
                            try tr.addChar(ch);
                        }
                        tr.negative = neg;
                        idx += i + 1;
                        curState = newState;
                    }
                },
                '.' => {
                    var newState = try alloc.create(State);
                    newState.* = State.init(alloc);
                    try states.append(newState);
                    var tr = try curState.addTransition(newState);
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
                    switch (pattern[idx + 1]) {
                        'w' => {
                            try tr.addString(word);
                        },
                        'W' => {
                            try tr.addString(word);
                            tr.negative = true;
                        },
                        'd' => {
                            try tr.addString(digit);
                        },
                        'D' => {
                            try tr.addString(digit);
                            tr.negative = true;
                        },
                        's' => {
                            try tr.addString(whitespace);
                        },
                        'S' => {
                            try tr.addString(whitespace);
                            tr.negative = true;
                        },
                        else => {
                            std.log.err("Found {c}", .{pattern[idx + 1]});
                            return error.Unimplemented;
                        },
                    }
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
        //var output = std.ArrayList(u8).init(alloc);
        //defer output.deinit();
        //var writer = output.writer();
        //try reg.printState(writer);
        //std.log.err("{s} => {s}", .{ tc.pattern, output.items });
        defer reg.deinit();
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
