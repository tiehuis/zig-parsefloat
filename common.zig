const std = @import("std");

/// A custom 64-bit floating point type, representing `f * 2^e`.
/// e is biased, so it be directly shifted into the exponent bits.
/// Negative exponent indicates an invalid result.
pub const BiasedFp = struct {
    /// The significant digits.
    f: u64,
    /// The biased, binary exponent.
    e: i32,

    pub fn zero() BiasedFp {
        return .{ .f = 0, .e = 0 };
    }

    pub fn zeroPow2(e: i32) BiasedFp {
        return .{ .f = 0, .e = e };
    }

    pub fn inf(comptime T: type) BiasedFp {
        return .{ .f = 0, .e = (1 << std.math.floatExponentBits(T)) - 1 };
    }

    pub fn eql(self: BiasedFp, other: BiasedFp) bool {
        return self.f == other.f and self.e == other.e;
    }

    pub fn toFloat(self: BiasedFp, comptime T: type, negative: bool) T {
        var word = self.f;
        word |= @intCast(u64, self.e) << std.math.floatMantissaBits(T);
        var f = floatFromU64(T, word);
        if (negative) f = -f;
        return f;
    }
};

pub fn floatFromU64(comptime T: type, v: u64) T {
    return switch (T) {
        f16 => @bitCast(f16, @truncate(u16, v)),
        f32 => @bitCast(f32, @truncate(u32, v)),
        f64 => @bitCast(f64, v),
        else => unreachable,
    };
}

/// Represents a parsed floating point value as its components.
pub const Number = struct {
    exponent: i64,
    mantissa: u64,
    negative: bool,
    /// More than 19 digits were found during parse
    many_digits: bool,
    /// The number was a hex-float (e.g. 0x1.234p567)
    hex: bool,
};

/// Determine if 8 bytes are all decimal digits.
/// This does not care about the order in which the bytes were loaded.
pub fn isEightDigits(v: u64) bool {
    const a = v +% 0x4646_4646_4646_4646;
    const b = v -% 0x3030_3030_3030_3030;
    return ((a | b) & 0x8080_8080_8080_8080) == 0;
}

pub fn isDigit(c: u8, comptime base: u8) bool {
    std.debug.assert(base == 10 or base == 16);

    return if (base == 10)
        '0' <= c and c <= '9'
    else
        '0' <= c and c <= '9' or 'a' <= c and c <= 'f' or 'A' <= c and c <= 'F';
}
