const std = @import("std");

pub const Regex = struct {
    alloc: std.mem.Allocator,
    components: []Component,

    const Component = union(enum) {
        TextBlock: []u8,
    };
    const Results = struct {
        alloc: std.mem.Allocator,
        pos: usize,
    };

    pub fn compile(alloc: std.mem.Allocator, regex: []const u8) !Regex {
        var list = std.ArrayList(Component).init(alloc);
        var currentBlock = std.ArrayList(u8).init(alloc);
        var idx: usize = 0;
        while (idx < regex.len) {
            switch (regex[idx]) {
                '\\' => {},
                else => {
                    std.log.warn("{c}", .{regex[idx]});
                    try currentBlock.append(regex[idx]);
                },
            }
            idx += 1;
        }
        try list.append(.{ .TextBlock = currentBlock.items });
        return Regex{
            .alloc = alloc,
            .components = list.items,
        };
    }
    pub fn deinit(self: *Regex) void {
        for (self.components) |c| {
            switch (c) {
                .TextBlock => |tb| {
                    self.alloc.free(tb);
                },
            }
        }
        self.alloc.free(self.components);
    }

    pub fn exec(reader: anytype) void {
        _ = reader;
    }
};

test {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const text =
        \\A spectre is haunting Europe – the spectre of communism. All the powers of old Europe have
        \\entered into a holy alliance to exorcise this spectre: Pope and Tsar, Metternich and Guizot,
        \\French Radicals and German police-spies.
        \\Where is the party in opposition that has not been decried as communistic by its opponents in
        \\power? Where is the opposition that has not hurled back the branding reproach of communism,
        \\against the more advanced opposition parties, as well as against its reactionary adversaries?
        \\Two things result from this fact:
        \\I. Communism is already acknowledged by all European powers to be itself a power.
        \\II. It is high time that Communists should openly, in the face of the whole world,
        \\publish their views, their aims, their tendencies, and meet this nursery tale of the
        \\Spectre of Communism with a manifesto of the party itself.
        \\To this end, Communists of various nationaliti es have assembled in London and sketched the
        \\following manifesto, to be published in the English, French, German, Italian, Flemish and Danish
        \\languages
    ;

    const t1 = "Communist";
    var r = try Regex.compile(gpa.allocator(), t1);
    defer r.deinit();
    _ = text;
    //r.exec(text);
}
