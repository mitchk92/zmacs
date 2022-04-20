const std = @import("std");
const Color = @import("../Color.zig");
pub const DisplayToken = struct {
    str: std.ArrayList(u8),
    face: Color.Face,
    pub fn create(alloc: std.mem.Allocator, str: []const u8, face: Color.Face) !DisplayToken {
        var stringArray = std.ArrayList(u8).init(alloc);
        try stringArray.appendSlice(str);
        return DisplayToken{
            .str = stringArray,
            .face = face,
        };
    }
    pub fn deinit(self: *DisplayToken) void {
        self.str.deinit();
    }
};

pub const DisplayString = struct {
    alloc: std.mem.Allocator,
    tokens: std.ArrayList(DisplayToken),
    pub fn createEmpty(alloc: std.mem.Allocator) DisplayString {
        return .{
            .alloc = alloc,
            .tokens = std.ArrayList(DisplayToken).init(alloc),
        };
    }
    pub fn append(self: *DisplayString, text: []const u8, face: Color.Face) !void {
        var token = try DisplayToken.create(self.alloc, text, face);
        try self.tokens.append(token);
    }
    pub fn deinit(self: *DisplayString) void {
        for (self.tokens.items) |*i| {
            i.deinit();
        }
        self.tokens.deinit();
    }
};

pub const DisplayMenu = struct {
    title: DisplayToken,
};

pub const DisplayScreen = struct {
    pub fn init(alloc: std.mem.Allocator) DisplayScreen {
        return .{
            .title = DisplayString.createEmpty(alloc),
            .menuITems = std.ArrayList(DisplayToken).init(alloc),
        };
    }
    pub fn addTitle(self: *DisplayScreen, str: []const u8) !void {}
    pub fn addMenuItem(self: *DisplayScreen, str: []const u8) *DisplayMenu {}
    title: DisplayString,
    menuItems: std.ArrayList(*DisplayMenu),
};

pub fn newString(alloc: std.mem.Allocator, str: []const u8, face: Color.Face) !DisplayString {
    var d = DisplayString.crateEmpty(alloc);
    d.append(str, face);
    return d;
}
