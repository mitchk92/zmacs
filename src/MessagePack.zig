const std = @import("std");

pub const ValueMap = struct {
    name: []const u8,
    val: Value,
};

pub const Value = union(ValueFormat) {
    String: []const u8,
    Int: i32,
    Uint: u32,
    Array: []const Value,
    Map: []const ValueMap,
    TimeStamp: u64,
};

pub const ValueFormat = enum {
    String,
    Int,
    Uint,
    Array,
    Map,
    TimeStamp,
};

pub const Format = enum {
    PositiveFixint,
    FixMap,
    FixArray,
    FixStr,
    Nil,
    False,
    True,
    Bin8,
    Bin16,
    Bin32,
    Ext8,
    Ext16,
    Ext32,
    Float32,
    Float64,
    Uint8,
    Uint16,
    Uint32,
    Uint64,
    Int8,
    Int16,
    Int32,
    Int64,
    FixExt1,
    FixExt2,
    FixExt4,
    FixExt8,
    FixExt16,
    Str8,
    Str16,
    Str32,
    Array16,
    Array32,
    Map16,
    Map32,
    NegativeFixint,
};

fn decodeByte(byte: u8) !Format {
    if ((byte & 0b10000000) == 0) return .PositiveFixint;

    switch (@truncate(u3, byte >> 5)) {
        0b101 => return .FixStr,
        0b111 => return .NegativeFixint,
        else => {},
    }
    switch (@truncate(u4, byte >> 4)) {
        0b1001 => return .FixArray,
        0b1000 => return .FixMap,
        else => {},
    }
    return switch (@truncate(u5, byte)) {
        0b00000 => .Nil,
        0b00001 => error.InvalidByte,
        0b00010 => .False,
        0b00011 => .True,
        0b00100 => .Bin8,
        0b00101 => .Bin16,
        0b00110 => .Bin32,
        0b00111 => .Ext8,
        0b01000 => .Ext16,
        0b01001 => .Ext32,
        0b01010 => .Float32,
        0b01011 => .Float64,
        0b01100 => .Uint8,
        0b01101 => .Uint16,
        0b01110 => .Uint32,
        0b01111 => .Uint64,
        0b10000 => .Int8,
        0b10001 => .Int16,
        0b10010 => .Int32,
        0b10011 => .Int64,
        0b10100 => .FixExt1,
        0b10101 => .FixExt2,
        0b10110 => .FixExt4,
        0b10111 => .FixExt8,
        0b11000 => .FixExt16,
        0b11001 => .Str8,
        0b11010 => .Str16,
        0b11011 => .Str32,
        0b11100 => .Array16,
        0b11101 => .Array32,
        0b11110 => .Map16,
        0b11111 => .Map32,
    };
}

fn getNBytes(n: usize, data: []const u8, idx: *usize) ![]const u8 {
    if (idx.* + n <= data.len) {
        const bytes = data[idx.* .. idx.* + n];
        idx.* += n;
        return bytes;
    } else {
        return error.TooManyBytes;
    }
}

pub fn readBytes(comptime T: type, bytes: []const u8) T {
    const input = @ptrCast(*align(1) const T, bytes.ptr);
    const res = std.mem.bigToNative(T, input.*);
    return res;
}

pub fn decodeStream(data: []const u8) !void {
    var idx: usize = 0;
    while (idx < data.len) {
        std.log.info("Byte:[{x}]", .{data[idx]});
        const byte = data[idx];
        const b = try decodeByte(byte);
        idx += 1;
        switch (b) {
            .PositiveFixint => {
                const val = @truncate(u7, byte);
                std.log.info("PositiveFixedInt:{}", .{val});
            },
            .FixMap => {
                const len = @truncate(u4, byte);
                std.log.info("FixedMap[{}]", .{len});
            },
            .Map16 => {
                const bytes = try getNBytes(2, data, &idx);
                const len = readBytes(u16, bytes);
                std.log.info("Map16[{}]", .{len});
            },
            .Map32 => {
                const bytes = try getNBytes(4, data, &idx);
                const len = readBytes(u32, bytes);
                std.log.info("Map32[{}]", .{len});
            },
            .FixArray => {
                const len = @truncate(u4, byte);
                std.log.info("FixedArray[{}]", .{len});
            },
            .Array16 => {
                const len_bytes = try getNBytes(2, data, &idx);
                const len = readBytes(u16, len_bytes);
                std.log.info("array16 {}", .{len});
            },
            .Array32 => {
                const len_bytes = try getNBytes(4, data, &idx);
                const len = readBytes(u32, len_bytes);
                std.log.info("array32 {}", .{len});
            },
            .FixStr => {
                const len = @truncate(u5, byte);
                const bytes = try getNBytes(len, data, &idx);
                std.log.info("String[{s}]", .{bytes});
            },
            .Str8 => {
                const len_b = try getNBytes(1, data, &idx);
                const len = readBytes(u8, len_b);
                const val = try getNBytes(len, data, &idx);
                std.log.info("String[{s}]", .{val});
            },
            .Str16 => {
                const len_b = try getNBytes(2, data, &idx);
                const len = readBytes(u16, len_b);
                const val = try getNBytes(len, data, &idx);
                std.log.info("String[{s}]", .{val});
            },
            .Str32 => {
                const len_b = try getNBytes(4, data, &idx);
                const len = readBytes(u16, len_b);
                const val = try getNBytes(len, data, &idx);
                std.log.info("String[{s}]", .{val});
            },
            .Nil => {
                std.log.info("Nill", .{});
            },
            .False => {
                std.log.info("False", .{});
            },
            .True => {
                std.log.info("True", .{});
            },
            .Bin8 => {
                const len_bytes = try getNBytes(1, data, &idx);
                const len = readBytes(u8, len_bytes);
                const bytes = try getNBytes(len, data, &idx);
                std.log.info("bin8 {}", .{std.fmt.fmtSliceHexUpper(bytes)});
            },
            .Bin16 => {
                const len_bytes = try getNBytes(2, data, &idx);
                const len = readBytes(u16, len_bytes);
                const bytes = try getNBytes(len, data, &idx);
                std.log.info("bin16 {}", .{std.fmt.fmtSliceHexUpper(bytes)});
            },
            .Bin32 => {
                const len_bytes = try getNBytes(4, data, &idx);
                const len = readBytes(u32, len_bytes);
                const bytes = try getNBytes(len, data, &idx);
                std.log.info("bin32 {}", .{std.fmt.fmtSliceHexUpper(bytes)});
            },
            .Ext8 => {
                const len_bytes = try getNBytes(1, data, &idx);
                const len = readBytes(u8, len_bytes);
                const extType = (try getNBytes(1, data, &idx))[0];
                const bytes = try getNBytes(len, data, &idx);
                std.log.info("ext8 {} {}", .{ extType, std.fmt.fmtSliceHexUpper(bytes) });
            },
            .Ext16 => {
                const len_bytes = try getNBytes(2, data, &idx);
                const len = readBytes(u16, len_bytes);
                const extType = (try getNBytes(1, data, &idx))[0];
                const bytes = try getNBytes(len, data, &idx);
                std.log.info("ext6 {} {}", .{ extType, std.fmt.fmtSliceHexUpper(bytes) });
            },
            .Ext32 => {
                const len_bytes = try getNBytes(4, data, &idx);
                const len = readBytes(u32, len_bytes);
                const extType = (try getNBytes(1, data, &idx))[0];
                const bytes = try getNBytes(len, data, &idx);
                std.log.info("ext32 {} {}", .{ extType, std.fmt.fmtSliceHexUpper(bytes) });
            },
            .Float32 => {
                const bytes = try getNBytes(4, data, &idx);
                const bytes_int = readBytes(u32, bytes);
                const val = @ptrCast(*const f32, &bytes_int).*;
                std.log.info("f32[{}]", .{val});
            },
            .Float64 => {
                const bytes = try getNBytes(8, data, &idx);
                const bytes_int = readBytes(u64, bytes);
                const val = @ptrCast(*const f64, &bytes_int).*;
                std.log.info("f64[{}]", .{val});
            },
            .Uint8 => {
                const bytes = try getNBytes(1, data, &idx);
                const val = readBytes(u8, bytes);
                std.log.info("U8[{}]", .{val});
            },
            .Uint16 => {
                const bytes = try getNBytes(2, data, &idx);
                const val = readBytes(u16, bytes);
                std.log.info("U16[{}]", .{val});
            },
            .Uint32 => {
                const bytes = try getNBytes(4, data, &idx);
                const val = readBytes(u32, bytes);
                std.log.info("U32[{}]", .{val});
            },
            .Uint64 => {
                const bytes = try getNBytes(8, data, &idx);
                const val = readBytes(u64, bytes);
                std.log.info("U64[{}]", .{val});
            },
            .Int8 => {
                const bytes = try getNBytes(1, data, &idx);
                const val = readBytes(i8, bytes);
                std.log.info("i8[{}]", .{val});
            },
            .Int16 => {
                const bytes = try getNBytes(2, data, &idx);
                const val = readBytes(i16, bytes);
                std.log.info("i16[{}]", .{val});
            },
            .Int32 => {
                const bytes = try getNBytes(4, data, &idx);
                const val = readBytes(i32, bytes);
                std.log.info("i32[{}]", .{val});
            },
            .Int64 => {
                const bytes = try getNBytes(8, data, &idx);
                const val = readBytes(i64, bytes);
                std.log.info("i64[{}]", .{val});
            },
            .FixExt1 => {
                const exttype = (try getNBytes(1, data, &idx))[0];
                const extdata = try getNBytes(1, data, &idx);
                std.log.info("fixext1 {}: {}", .{ exttype, std.fmt.fmtSliceHexUpper(extdata) });
            },
            .FixExt2 => {
                const exttype = (try getNBytes(1, data, &idx))[0];
                const extdata = try getNBytes(2, data, &idx);
                std.log.info("fixext2 {}: {}", .{ exttype, std.fmt.fmtSliceHexUpper(extdata) });
            },
            .FixExt4 => {
                const exttype = (try getNBytes(1, data, &idx))[0];
                const extdata = try getNBytes(4, data, &idx);
                std.log.info("fixext4 {}: {}", .{ exttype, std.fmt.fmtSliceHexUpper(extdata) });
            },
            .FixExt8 => {
                const exttype = (try getNBytes(1, data, &idx))[0];
                const extdata = try getNBytes(8, data, &idx);
                std.log.info("fixext8 {}: {}", .{ exttype, std.fmt.fmtSliceHexUpper(extdata) });
            },
            .FixExt16 => {
                const exttype = (try getNBytes(1, data, &idx))[0];
                const extdata = try getNBytes(16, data, &idx);
                std.log.info("fixext16 {}: {}", .{ exttype, std.fmt.fmtSliceHexUpper(extdata) });
            },
            .NegativeFixint => return error.NotImplemented,
        }
    }
}

pub fn encodeStream(
    writer: anytype,
) void {}

test {}

pub fn tests() !void {
    const stream1 = [_]u8{ 0x9c, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x00, 0x0a, 0xce, 0x00, 0x01, 0xe2, 0xa4 };
    std.log.info("stream1", .{});
    try decodeStream(stream1[0..]);

    const stream2 = [_]u8{ 0x9d, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x00, 0x0a, 0xce, 0x00, 0x01, 0xe2, 0xa4, 0xa5, 0x74, 0x68, 0x69, 0x6e, 0x67 };
    //[
    //1,
    //2,3,4,5,6,7,8,9,0,10,123556,"thing"
    //]
    std.log.info("stream2", .{});
    try decodeStream(stream2[0..]);
    const stream3 = [_]u8{ 0x82, 0xa5, 0x74, 0x68, 0x69, 0x6e, 0x67, 0xcc, 0x86, 0xa6, 0x74, 0x68, 0x69, 0x6e, 0x67, 0x32, 0xcc, 0x86 };
    //{
    //"thing":134,
    //"thing2":134,
    //}
    std.log.info("stream3", .{});
    try decodeStream(stream3[0..]);

    const stream4 = [_]u8{ 0x81, 0xA5, 0x74, 0x68, 0x69, 0x6E, 0x67, 0xD9, 0x55, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x63, 0x64, 0x61, 0x62, 0x61, 0x63, 0x64 };
    //{
    //"thing":"abcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabcdabacd",
    //}

    std.log.info("stream4", .{});
    try decodeStream(stream4[0..]);

    const stream5 = [_]u8{ 0x81, 0xA5, 0x74, 0x68, 0x69, 0x6E, 0x67, 0xCB, 0x40, 0x22, 0x48, 0xB4, 0x39, 0x58, 0x10, 0x62 };
    std.log.info("stream5", .{});
    try decodeStream(stream5[0..]);
}
