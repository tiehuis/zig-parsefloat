//! A wrapper over a byte-slice, providing a Reader-like interface.

const std = @import("std");
const FloatStream = @This();

slice: []const u8,
offset: usize,

pub fn init(s: []const u8) FloatStream {
    return .{ .slice = s, .offset = 0 };
}

pub fn reset(self: *FloatStream) void {
    self.offset = 0;
}

pub fn len(self: FloatStream) usize {
    if (self.offset > self.slice.len) {
        return 0;
    }
    return self.slice.len - self.offset;
}

pub fn hasLen(self: FloatStream, n: usize) bool {
    return self.offset + n <= self.slice.len;
}

pub fn firstUnchecked(self: FloatStream) u8 {
    return self.slice[self.offset];
}

pub fn first(self: FloatStream) ?u8 {
    return if (self.hasLen(1))
        return self.firstUnchecked()
    else
        null;
}

pub fn isEmpty(self: FloatStream) bool {
    return !self.hasLen(1);
}

pub fn firstIs(self: FloatStream, c: u8) bool {
    if (self.first()) |ok| {
        return ok == c;
    }
    return false;
}

pub fn firstIs2(self: FloatStream, c1: u8, c2: u8) bool {
    if (self.first()) |ok| {
        return ok == c1 or ok == c2;
    }
    return false;
}

pub fn firstIsDigit(self: FloatStream) bool {
    if (self.first()) |ok| {
        return std.ascii.isDigit(ok);
    }
    return false;
}

pub fn advance(self: *FloatStream, n: usize) void {
    self.offset += n;
}

pub fn skipChars(self: *FloatStream, c: u8) void {
    while (self.firstIs(c)) : (self.advance(1)) {}
}

pub fn skipChars2(self: *FloatStream, c1: u8, c2: u8) void {
    while (self.firstIs2(c1, c2)) : (self.advance(1)) {}
}

pub fn readU64Unchecked(self: FloatStream) u64 {
    return std.mem.readIntSliceLittle(u64, self.slice);
}

pub fn readU64(self: FloatStream) ?u64 {
    if (self.hasLen(8)) {
        return self.readU64Unchecked();
    }
    return null;
}

pub fn scanDigit(self: *FloatStream) ?u8 {
    if (self.first()) |ok| {
        if ('0' <= ok and ok <= '9') {
            self.advance(1);
            return ok - '0';
        }
    }
    return null;
}
