const std = @import("std");

pub const Regex = struct {
    alloc: std.mem.Allocator,
    states: *State,
    startingStates: []*State,
    strings: [][]u8,
    const Transition = struct {
        pub fn checkChar(self: Transition, ch: u8) bool {
            if (std.mem.containsAtLeast(u8, self.chars, &.{u8})) {
                return !negate;
            } else {
                return negate;
            }
        }
        chars: []const u8,
        negate: bool,
        nextState: *State,
    };

    const State = struct {
        pub fn init(alloc: std.mem.Allocator, isSuccess: bool) State {
            return .{
                .alloc = alloc,
                .transition = std.ArrayList(Transition).init(alloc),
                .isSuccess = isSuccess,
            };
        }
        pub fn deinit(self: State) void {
            for (self.alloc.transition) |t| {
                self.alloc.free(t.transition);
            }
            self.transition.deinit();
        }
        pub fn addTransition(self: *State, chars: []u8) !*State {
            var state = try self.alloc.create(State);
            state.* = State.init(self.alloc, false);
            try self.transition.append(.{
                .transition = try self.alloc.dupe(u8, chars),
                .nextState = state,
            });
            return state;
        }
        alloc: std.mem.Allocator,
    };

    pub fn compile(regex: []const u8, ar_alloc: std.mem.Allocator) !Regex {
        var arena = std.heap.ArenaAllocator.init(ar_alloc);
        errdefer arena.deinit();
        var alloc = arena.allocator();
        var beginStates = std.ArrayList(*State).init(alloc);
        var state1 = try alloc.create(State);
        state1.* = State.init(alloc, false);
        try beginStates.append(state1);
        var curState = state1;
        for (regex) |ch| {
            var st = [1]u8{ch};
            var nextState = try curState.addTransition(st[0..]);
            curState = nextState;
        }
        curState.isSuccess = true;
        return Regex{
            .backingAlloc = alloc,
            .arena = arena,
            .startingStates = beginStates.items,
        };
    }
    pub fn deinit(self: *Regex) void {
        self.arena.deinit();
    }
    const Thread = struct {
        curState: *State,
        start: usize,
    };
    const Result = struct {
        start: usize,
        end: usize,
    };
    pub fn exec(self: *Regex, text: []const u8) ![]Result {
        var results = std.ArrayList(Result).init(self.arena.allocator());

        var activeStates = std.ArrayList(Thread).init(self.arena.allocator());
        for (text) |ch, idx| {
            var newStates = std.ArrayList(Thread).init(self.arena.allocator());
            for (activeStates.items) |st| {
                for (st.curState.transition.items) |trans| {
                    var check = trans.check(ch);
                    if (check) |ns| {
                        if (ns.isSuccess) {
                            try results.append(.{ .start = st.start, .end = idx });
                        }
                        try newStates.append(.{ .curState = ns, .start = st.start });
                    }
                }
            }
            activeStates.deinit();
            activeStates = newStates;
            for (self.startingStates) |st| {
                for (st.transition.items) |trans| {
                    if (trans.check(ch)) |ns| {
                        try activeStates.append(.{ .curState = ns, .start = idx });
                    }
                }
            }
        }

        return results.items;
    }
};

test {
    const text1 = "Hello Hello Hello";
    const reg = "Hello";
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var regex = try Regex.compile(reg, alloc);
    defer regex.deinit();
    const res = try regex.exec(text1);
    for (res) |r| {
        std.log.warn("{} : {}", .{ r.start, r.end });
    }
}
