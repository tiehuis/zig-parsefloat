//! Arbitrary-precision decimal class for fallback algorithms.
//!
//! This is only used if the fast-path (native floats) and
//! the Eisel-Lemire algorithm are unable to unambiguously
//! determine the float.
//!
//! The technique used is "Simple Decimal Conversion", developed
//! by Nigel Tao and Ken Thompson. A detailed description of the
//! algorithm can be found in "ParseNumberF64 by Simple Decimal Conversion",
//! available online: <https://nigeltao.github.io/blog/2020/parse-number-f64-simple.html>.
//!
//! Big-decimal implementation. We do not use the big.Int routines since we only require a maximum
//! fixed region of memory. Further, we require only a small subset of operations.

const std = @import("std");
const math = std.math;
const Decimal = @This();
const FloatStream = @import("FloatStream.zig");
const isEightDigits = @import("common.zig").isEightDigits;

/// The maximum number of digits required to unambiguously round a float.
///
/// For a double-precision IEEE-754 float, this required 767 digits,
/// so we store the max digits + 1.
///
/// We can exactly represent a float in radix `b` from radix 2 if
/// `b` is divisible by 2. This function calculates the exact number of
/// digits required to exactly represent that float.
///
/// According to the "Handbook of Floating Point Arithmetic",
/// for IEEE754, with emin being the min exponent, p2 being the
/// precision, and b being the radix, the number of digits follows as:
///
/// `−emin + p2 + ⌊(emin + 1) log(2, b) − log(1 − 2^(−p2), b)⌋`
///
/// For f32, this follows as:
///     emin = -126
///     p2 = 24
///
/// For f64, this follows as:
///     emin = -1022
///     p2 = 53
///
/// In Python:
///     `-emin + p2 + math.floor((emin+ 1)*math.log(2, b)-math.log(1-2**(-p2), b))`
pub const max_digits = 768;
/// The max digits that can be exactly represented in a 64-bit integer.
pub const max_digits_without_overflow = 19;
pub const decimal_point_range = 2047;

/// The number of significant digits in the decimal.
num_digits: usize,
/// The offset of the decimal point in the significant digits.
decimal_point: i32,
/// If the number of significant digits stored in the decimal is truncated.
truncated: bool,
/// buffer of the raw digits, in the range [0, 9].
digits: [max_digits]u8,

pub fn new() Decimal {
    return .{
        .num_digits = 0,
        .decimal_point = 0,
        .truncated = false,
        .digits = [_]u8{0} ** max_digits,
    };
}

/// Append a digit to the buffer
pub fn tryAddDigit(self: *Decimal, digit: u8) void {
    if (self.num_digits < max_digits) {
        self.digits[self.num_digits] = digit;
    }
    self.num_digits += 1;
}

/// Trim trailing zeroes from the buffer
pub fn trim(self: *Decimal) void {
    // All of the following calls to `Decimal::trim` can't panic because:
    //
    //  1. `parse_decimal` sets `num_digits` to a max of `max_digits`.
    //  2. `right_shift` sets `num_digits` to `write_index`, which is bounded by `num_digits`.
    //  3. `left_shift` `num_digits` to a max of `max_digits`.
    //
    // Trim is only called in `right_shift` and `left_shift`.
    std.debug.assert(self.num_digits <= max_digits);
    while (self.num_digits != 0 and self.digits[self.num_digits - 1] == 0) {
        self.num_digits -= 1;
    }
}

pub fn round(self: *Decimal) u64 {
    if (self.num_digits == 0 or self.decimal_point < 0) {
        return 0;
    } else if (self.decimal_point > 18) {
        return 0xffff_ffff_ffff_ffff;
    }

    const dp = @intCast(usize, self.decimal_point);
    var n: u64 = 0;

    var i: usize = 0;
    while (i < dp) : (i += 1) {
        n *= 10;
        if (i < self.num_digits) {
            n += @as(u64, self.digits[i]);
        }
    }

    var round_up = false;
    if (dp < self.num_digits) {
        round_up = self.digits[dp] >= 5;
        if (self.digits[dp] == 5 and dp + 1 == self.num_digits) {
            round_up = self.truncated or ((dp != 0) and (1 & self.digits[dp - 1] != 0));
        }
    }
    if (round_up) {
        n += 1;
    }
    return n;
}

/// Computes decimal * 2^shift.
pub fn leftShift(self: *Decimal, shift: usize) void {
    if (self.num_digits == 0) {
        return;
    }
    const num_new_digits = self.numberOfDigitsLeftShift(shift);
    var read_index = self.num_digits;
    var write_index = self.num_digits + num_new_digits;
    var n: u64 = 0;
    while (read_index != 0) {
        read_index -= 1;
        write_index -= 1;
        n += math.shl(u64, self.digits[read_index], shift);

        const quotient = n / 10;
        const remainder = n - (10 * quotient);
        if (write_index < max_digits) {
            self.digits[write_index] = @intCast(u8, remainder);
        } else if (remainder > 0) {
            self.truncated = true;
        }
        n = quotient;
    }
    while (n > 0) {
        write_index -= 1;

        const quotient = n / 10;
        const remainder = n - (10 * quotient);
        if (write_index < max_digits) {
            self.digits[write_index] = @intCast(u8, remainder);
        } else if (remainder > 0) {
            self.truncated = true;
        }
        n = quotient;
    }

    self.num_digits += num_new_digits;
    if (self.num_digits > max_digits) {
        self.num_digits = max_digits;
    }
    self.decimal_point += @intCast(i32, num_new_digits);
    self.trim();
}

/// Computes decimal * 2^-shift.
pub fn rightShift(self: *Decimal, shift: usize) void {
    var read_index: usize = 0;
    var write_index: usize = 0;
    var n: u64 = 0;
    while (math.shr(u64, n, shift) == 0) {
        if (read_index < self.num_digits) {
            n = (10 * n) + self.digits[read_index];
            read_index += 1;
        } else if (n == 0) {
            return;
        } else {
            while (math.shr(u64, n, shift) == 0) {
                n *= 10;
                read_index += 1;
            }
            break;
        }
    }

    self.decimal_point -= @intCast(i32, read_index) - 1;
    if (self.decimal_point < -decimal_point_range) {
        self.num_digits = 0;
        self.decimal_point = 0;
        self.truncated = false;
        return;
    }

    const mask = math.shl(u64, 1, shift) - 1;
    while (read_index < self.num_digits) {
        const new_digit = @intCast(u8, math.shr(u64, n, shift));
        n = (10 * (n & mask)) + self.digits[read_index];
        read_index += 1;
        self.digits[write_index] = new_digit;
        write_index += 1;
    }
    while (n > 0) {
        const new_digit = @intCast(u8, math.shr(u64, n, shift));
        n = 10 * (n & mask);
        if (write_index < max_digits) {
            self.digits[write_index] = new_digit;
            write_index += 1;
        } else if (new_digit > 0) {
            self.truncated = true;
        }
    }
    self.num_digits = write_index;
    self.trim();
}

/// Parse a bit integer representation of the float as a decimal.
// We do not verify underscores in this path since these will have been verified
// via parse.parseNumber so can assume the number is well-formed.
// This code-path does not have to handle hex-floats since these will always be handled via another
// function prior to this.
pub fn parse(s: []const u8) Decimal {
    var d = Decimal.new();
    var stream = FloatStream.init(s);

    stream.skipChars2('0', '_');
    while (stream.scanDigit(10)) |digit| {
        d.tryAddDigit(digit);
    }

    if (stream.firstIs('.')) {
        stream.advance(1);
        const marker = stream.offsetTrue();

        // Skip leading zeroes
        if (d.num_digits == 0) {
            stream.skipChars('0');
        }

        // TODO: This is causing test failures. We are writing the start of the stream out again
        // to the incorrect spot. Recheck logic.
        if (false) {
            while (stream.hasLen(8) and d.num_digits + 8 < max_digits) {
                const v = stream.readU64Unchecked();
                if (!isEightDigits(v)) {
                    break;
                }
                std.mem.writeIntSliceLittle(u64, d.digits[d.num_digits..], v - 0x3030_3030_3030_3030);
                d.num_digits += 8;
                stream.advance(8);
            }
        }

        while (stream.scanDigit(10)) |digit| {
            d.tryAddDigit(digit);
        }
        d.decimal_point = @intCast(i32, marker) - @intCast(i32, stream.offsetTrue());
    }
    if (d.num_digits != 0) {
        // Ignore trailing zeros if any
        var n_trailing_zeros: usize = 0;
        var i = stream.offsetTrue() - 1;
        while (true) {
            if (s[i] == '0') {
                n_trailing_zeros += 1;
            } else if (s[i] != '.') {
                break;
            }

            i -= 1;
            if (i == 0) break;
        }
        d.decimal_point += @intCast(i32, n_trailing_zeros);
        d.num_digits -= n_trailing_zeros;
        d.decimal_point += @intCast(i32, d.num_digits);
        if (d.num_digits > max_digits) {
            d.truncated = true;
            d.num_digits = max_digits;
        }
    }
    if (stream.firstIs2('e', 'E')) {
        stream.advance(1);
        var neg_exp = false;
        if (stream.firstIs('-')) {
            neg_exp = true;
            stream.advance(1);
        } else if (stream.firstIs('+')) {
            stream.advance(1);
        }
        var exp_num: i32 = 0;
        while (stream.scanDigit(10)) |digit| {
            if (exp_num < 0x10000) {
                exp_num = 10 * exp_num + digit;
            }
        }
        d.decimal_point += if (neg_exp) -exp_num else exp_num;
    }

    var i = d.num_digits;
    while (i < max_digits_without_overflow) : (i += 1) {
        d.digits[i] = 0;
    }

    return d;
}

pub fn numberOfDigitsLeftShift(self: *Decimal, shift_: usize) usize {
    var shift = shift_;

    const table = [_]u16{
        0x0000, 0x0800, 0x0801, 0x0803, 0x1006, 0x1009, 0x100D, 0x1812, 0x1817, 0x181D, 0x2024,
        0x202B, 0x2033, 0x203C, 0x2846, 0x2850, 0x285B, 0x3067, 0x3073, 0x3080, 0x388E, 0x389C,
        0x38AB, 0x38BB, 0x40CC, 0x40DD, 0x40EF, 0x4902, 0x4915, 0x4929, 0x513E, 0x5153, 0x5169,
        0x5180, 0x5998, 0x59B0, 0x59C9, 0x61E3, 0x61FD, 0x6218, 0x6A34, 0x6A50, 0x6A6D, 0x6A8B,
        0x72AA, 0x72C9, 0x72E9, 0x7B0A, 0x7B2B, 0x7B4D, 0x8370, 0x8393, 0x83B7, 0x83DC, 0x8C02,
        0x8C28, 0x8C4F, 0x9477, 0x949F, 0x94C8, 0x9CF2, 0x051C, 0x051C, 0x051C, 0x051C,
    };

    const table_pow5 = [_]u8{
        5, 2, 5, 1, 2, 5, 6, 2, 5, 3, 1, 2, 5, 1, 5, 6, 2, 5, 7, 8, 1, 2, 5, 3, 9, 0, 6, 2, 5, 1,
        9, 5, 3, 1, 2, 5, 9, 7, 6, 5, 6, 2, 5, 4, 8, 8, 2, 8, 1, 2, 5, 2, 4, 4, 1, 4, 0, 6, 2, 5,
        1, 2, 2, 0, 7, 0, 3, 1, 2, 5, 6, 1, 0, 3, 5, 1, 5, 6, 2, 5, 3, 0, 5, 1, 7, 5, 7, 8, 1, 2,
        5, 1, 5, 2, 5, 8, 7, 8, 9, 0, 6, 2, 5, 7, 6, 2, 9, 3, 9, 4, 5, 3, 1, 2, 5, 3, 8, 1, 4, 6,
        9, 7, 2, 6, 5, 6, 2, 5, 1, 9, 0, 7, 3, 4, 8, 6, 3, 2, 8, 1, 2, 5, 9, 5, 3, 6, 7, 4, 3, 1,
        6, 4, 0, 6, 2, 5, 4, 7, 6, 8, 3, 7, 1, 5, 8, 2, 0, 3, 1, 2, 5, 2, 3, 8, 4, 1, 8, 5, 7, 9,
        1, 0, 1, 5, 6, 2, 5, 1, 1, 9, 2, 0, 9, 2, 8, 9, 5, 5, 0, 7, 8, 1, 2, 5, 5, 9, 6, 0, 4, 6,
        4, 4, 7, 7, 5, 3, 9, 0, 6, 2, 5, 2, 9, 8, 0, 2, 3, 2, 2, 3, 8, 7, 6, 9, 5, 3, 1, 2, 5, 1,
        4, 9, 0, 1, 1, 6, 1, 1, 9, 3, 8, 4, 7, 6, 5, 6, 2, 5, 7, 4, 5, 0, 5, 8, 0, 5, 9, 6, 9, 2,
        3, 8, 2, 8, 1, 2, 5, 3, 7, 2, 5, 2, 9, 0, 2, 9, 8, 4, 6, 1, 9, 1, 4, 0, 6, 2, 5, 1, 8, 6,
        2, 6, 4, 5, 1, 4, 9, 2, 3, 0, 9, 5, 7, 0, 3, 1, 2, 5, 9, 3, 1, 3, 2, 2, 5, 7, 4, 6, 1, 5,
        4, 7, 8, 5, 1, 5, 6, 2, 5, 4, 6, 5, 6, 6, 1, 2, 8, 7, 3, 0, 7, 7, 3, 9, 2, 5, 7, 8, 1, 2,
        5, 2, 3, 2, 8, 3, 0, 6, 4, 3, 6, 5, 3, 8, 6, 9, 6, 2, 8, 9, 0, 6, 2, 5, 1, 1, 6, 4, 1, 5,
        3, 2, 1, 8, 2, 6, 9, 3, 4, 8, 1, 4, 4, 5, 3, 1, 2, 5, 5, 8, 2, 0, 7, 6, 6, 0, 9, 1, 3, 4,
        6, 7, 4, 0, 7, 2, 2, 6, 5, 6, 2, 5, 2, 9, 1, 0, 3, 8, 3, 0, 4, 5, 6, 7, 3, 3, 7, 0, 3, 6,
        1, 3, 2, 8, 1, 2, 5, 1, 4, 5, 5, 1, 9, 1, 5, 2, 2, 8, 3, 6, 6, 8, 5, 1, 8, 0, 6, 6, 4, 0,
        6, 2, 5, 7, 2, 7, 5, 9, 5, 7, 6, 1, 4, 1, 8, 3, 4, 2, 5, 9, 0, 3, 3, 2, 0, 3, 1, 2, 5, 3,
        6, 3, 7, 9, 7, 8, 8, 0, 7, 0, 9, 1, 7, 1, 2, 9, 5, 1, 6, 6, 0, 1, 5, 6, 2, 5, 1, 8, 1, 8,
        9, 8, 9, 4, 0, 3, 5, 4, 5, 8, 5, 6, 4, 7, 5, 8, 3, 0, 0, 7, 8, 1, 2, 5, 9, 0, 9, 4, 9, 4,
        7, 0, 1, 7, 7, 2, 9, 2, 8, 2, 3, 7, 9, 1, 5, 0, 3, 9, 0, 6, 2, 5, 4, 5, 4, 7, 4, 7, 3, 5,
        0, 8, 8, 6, 4, 6, 4, 1, 1, 8, 9, 5, 7, 5, 1, 9, 5, 3, 1, 2, 5, 2, 2, 7, 3, 7, 3, 6, 7, 5,
        4, 4, 3, 2, 3, 2, 0, 5, 9, 4, 7, 8, 7, 5, 9, 7, 6, 5, 6, 2, 5, 1, 1, 3, 6, 8, 6, 8, 3, 7,
        7, 2, 1, 6, 1, 6, 0, 2, 9, 7, 3, 9, 3, 7, 9, 8, 8, 2, 8, 1, 2, 5, 5, 6, 8, 4, 3, 4, 1, 8,
        8, 6, 0, 8, 0, 8, 0, 1, 4, 8, 6, 9, 6, 8, 9, 9, 4, 1, 4, 0, 6, 2, 5, 2, 8, 4, 2, 1, 7, 0,
        9, 4, 3, 0, 4, 0, 4, 0, 0, 7, 4, 3, 4, 8, 4, 4, 9, 7, 0, 7, 0, 3, 1, 2, 5, 1, 4, 2, 1, 0,
        8, 5, 4, 7, 1, 5, 2, 0, 2, 0, 0, 3, 7, 1, 7, 4, 2, 2, 4, 8, 5, 3, 5, 1, 5, 6, 2, 5, 7, 1,
        0, 5, 4, 2, 7, 3, 5, 7, 6, 0, 1, 0, 0, 1, 8, 5, 8, 7, 1, 1, 2, 4, 2, 6, 7, 5, 7, 8, 1, 2,
        5, 3, 5, 5, 2, 7, 1, 3, 6, 7, 8, 8, 0, 0, 5, 0, 0, 9, 2, 9, 3, 5, 5, 6, 2, 1, 3, 3, 7, 8,
        9, 0, 6, 2, 5, 1, 7, 7, 6, 3, 5, 6, 8, 3, 9, 4, 0, 0, 2, 5, 0, 4, 6, 4, 6, 7, 7, 8, 1, 0,
        6, 6, 8, 9, 4, 5, 3, 1, 2, 5, 8, 8, 8, 1, 7, 8, 4, 1, 9, 7, 0, 0, 1, 2, 5, 2, 3, 2, 3, 3,
        8, 9, 0, 5, 3, 3, 4, 4, 7, 2, 6, 5, 6, 2, 5, 4, 4, 4, 0, 8, 9, 2, 0, 9, 8, 5, 0, 0, 6, 2,
        6, 1, 6, 1, 6, 9, 4, 5, 2, 6, 6, 7, 2, 3, 6, 3, 2, 8, 1, 2, 5, 2, 2, 2, 0, 4, 4, 6, 0, 4,
        9, 2, 5, 0, 3, 1, 3, 0, 8, 0, 8, 4, 7, 2, 6, 3, 3, 3, 6, 1, 8, 1, 6, 4, 0, 6, 2, 5, 1, 1,
        1, 0, 2, 2, 3, 0, 2, 4, 6, 2, 5, 1, 5, 6, 5, 4, 0, 4, 2, 3, 6, 3, 1, 6, 6, 8, 0, 9, 0, 8,
        2, 0, 3, 1, 2, 5, 5, 5, 5, 1, 1, 1, 5, 1, 2, 3, 1, 2, 5, 7, 8, 2, 7, 0, 2, 1, 1, 8, 1, 5,
        8, 3, 4, 0, 4, 5, 4, 1, 0, 1, 5, 6, 2, 5, 2, 7, 7, 5, 5, 5, 7, 5, 6, 1, 5, 6, 2, 8, 9, 1,
        3, 5, 1, 0, 5, 9, 0, 7, 9, 1, 7, 0, 2, 2, 7, 0, 5, 0, 7, 8, 1, 2, 5, 1, 3, 8, 7, 7, 7, 8,
        7, 8, 0, 7, 8, 1, 4, 4, 5, 6, 7, 5, 5, 2, 9, 5, 3, 9, 5, 8, 5, 1, 1, 3, 5, 2, 5, 3, 9, 0,
        6, 2, 5, 6, 9, 3, 8, 8, 9, 3, 9, 0, 3, 9, 0, 7, 2, 2, 8, 3, 7, 7, 6, 4, 7, 6, 9, 7, 9, 2,
        5, 5, 6, 7, 6, 2, 6, 9, 5, 3, 1, 2, 5, 3, 4, 6, 9, 4, 4, 6, 9, 5, 1, 9, 5, 3, 6, 1, 4, 1,
        8, 8, 8, 2, 3, 8, 4, 8, 9, 6, 2, 7, 8, 3, 8, 1, 3, 4, 7, 6, 5, 6, 2, 5, 1, 7, 3, 4, 7, 2,
        3, 4, 7, 5, 9, 7, 6, 8, 0, 7, 0, 9, 4, 4, 1, 1, 9, 2, 4, 4, 8, 1, 3, 9, 1, 9, 0, 6, 7, 3,
        8, 2, 8, 1, 2, 5, 8, 6, 7, 3, 6, 1, 7, 3, 7, 9, 8, 8, 4, 0, 3, 5, 4, 7, 2, 0, 5, 9, 6, 2,
        2, 4, 0, 6, 9, 5, 9, 5, 3, 3, 6, 9, 1, 4, 0, 6, 2, 5,
    };

    shift &= 63;
    const x_a = table[shift];
    const x_b = table[shift + 1];
    const num_new_digits = x_a >> 11;
    const pow5_a = 0x7ff & x_a;
    const pow5_b = 0x7ff & x_b;

    const pow5 = table_pow5[pow5_a..];
    for (pow5[0 .. pow5_b - pow5_a]) |p5, i| {
        if (i >= self.num_digits) {
            return num_new_digits - 1;
        } else if (self.digits[i] == p5) {
            continue;
        } else if (self.digits[i] < p5) {
            return num_new_digits - 1;
        } else {
            return num_new_digits;
        }
    }

    return num_new_digits;
}
