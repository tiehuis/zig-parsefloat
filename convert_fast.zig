//! Representation of a float as the signficant digits and exponent.
//! The fast path algorithm using machine-sized integers and floats.
//!
//! This only works if both the mantissa and the exponent can be exactly
//! represented as a machine float, since IEE-754 guarantees no rounding
//! will occur.
//!
//! There is an exception: disguised fast-path cases, where we can shift
//! powers-of-10 from the exponent to the significant digits.

const std = @import("std");
const math = std.math;
const Number = @import("common.zig").Number;
const floatFromU64 = @import("common.zig").floatFromU64;

fn FastPathLimits(comptime T: type) type {
    return switch (T) {
        f32 => struct {
            pub const min_exponent = -10;
            pub const max_exponent = 10;
            pub const max_exponent_disguised = 17;
            pub const max_mantissa = 2 << math.floatMantissaBits(T);
        },
        f64 => struct {
            pub const min_exponent = -22;
            pub const max_exponent = 22;
            pub const max_exponent_disguised = 37;
            pub const max_mantissa = 2 << math.floatMantissaBits(T);
        },
        else => @compileError("only f32 and f64 are supported"),
    };
}

fn isFastPath(comptime T: type, n: Number) bool {
    const limits = FastPathLimits(T);

    return limits.min_exponent <= n.exponent and
        n.exponent <= limits.max_exponent_disguised and
        n.mantissa <= limits.max_mantissa and
        !n.many_digits;
}

// upper bound for tables is floor(mantissaDigits(T) / log2(5))
// for f64 this is floor(53 / log2(5)) = 22.
//
// we only support f64 maximum at this stage
fn fastPow10(comptime T: type, i: usize) T {
    return switch (T) {
        f32 => {
            return ([16]f32{
                1e0, 1e1, 1e2,  1e3, 1e4, 1e5, 1e6, 1e7,
                1e8, 1e9, 1e10, 0,   0,   0,   0,   0,
            })[i & 15];
        },
        f64 => {
            return ([32]f64{
                1e0,  1e1,  1e2,  1e3,  1e4,  1e5,  1e6,  1e7,
                1e8,  1e9,  1e10, 1e11, 1e12, 1e13, 1e14, 1e15,
                1e16, 1e17, 1e18, 1e19, 1e20, 1e21, 1e22, 0,
                0,    0,    0,    0,    0,    0,    0,    0,
            })[i & 31];
        },
        else => @compileError("only f32 and f64 are supported"),
    };
}

const int_pow10 = [_]u64{
    1,             10,             100,             1000,
    10000,         100000,         1000000,         10000000,
    100000000,     1000000000,     10000000000,     100000000000,
    1000000000000, 10000000000000, 100000000000000, 1000000000000000,
};

pub fn convertFast(comptime T: type, n: Number) ?T {
    if (!isFastPath(T, n)) {
        return null;
    }

    // TODO: x86 (no SSE/SSE2) requires x87 FPU to be setup correctly with fldcw
    const limits = FastPathLimits(T);

    var value: T = 0;
    if (n.exponent <= limits.max_exponent) {
        // normal fast path
        value = @intToFloat(T, n.mantissa);
        value = if (n.exponent < 0)
            value / fastPow10(T, @intCast(usize, -n.exponent))
        else
            value * fastPow10(T, @intCast(usize, n.exponent));
    } else {
        // disguised fast path
        const shift = n.exponent - limits.max_exponent;
        const mantissa = math.mul(u64, n.mantissa, int_pow10[@intCast(usize, shift)]) catch return null;
        if (mantissa > limits.max_mantissa) {
            return null;
        }
        value = @intToFloat(T, mantissa) * fastPow10(T, limits.max_exponent);
    }

    if (n.negative) {
        value = -value;
    }
    return value;
}
