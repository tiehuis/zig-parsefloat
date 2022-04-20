const std = @import("std");
const common = @import("common.zig");
const FloatStream = @import("FloatStream.zig");
const isEightDigits = common.isEightDigits;
const Number = common.Number;

const min_19digit_int: u64 = 100_0000_0000_0000_0000;

/// Parse 8 digits, loaded as bytes in little-endian order.
///
/// This uses the trick where every digit is in [0x030, 0x39],
/// and therefore can be parsed in 3 multiplications, much
/// faster than the normal 8.
///
/// This is based off the algorithm described in "Fast numeric string to
/// int", available here: <https://johnnylee-sde.github.io/Fast-numeric-string-to-int/>.
fn parse8Digits(v_: u64) u64 {
    var v = v_;
    const mask = 0x0000_00ff_0000_00ff;
    const mul1 = 0x000f_4240_0000_0064;
    const mul2 = 0x0000_2710_0000_0001;
    v -= 0x3030_3030_3030_3030;
    v = (v * 10) + (v >> 8); // will not overflow, fits in 63 bits
    const v1 = (v & mask) *% mul1;
    const v2 = ((v >> 16) & mask) *% mul2;
    return @as(u64, @truncate(u32, (v1 +% v2) >> 32));
}

/// Parse digits until a non-digit character is found.
fn tryParseDigits(stream: *FloatStream, x: *u64) void {
    while (stream.scanDigit()) |digit| {
        x.* *%= 10;
        x.* +%= digit;
    }
}

/// Try to parse 8 digits at a time, using an optimized algorithm.
fn tryParse8Digits(stream: *FloatStream, x: *u64) void {
    if (stream.readU64()) |v| {
        if (isEightDigits(v)) {
            x.* = x.* *% 1_0000_0000 +% parse8Digits(v);
            stream.advance(8);

            if (stream.readU64()) |w| {
                if (isEightDigits(w)) {
                    x.* = x.* *% 1_0000_0000 +% parse8Digits(v);
                    stream.advance(8);
                }
            }
        }
    }
}

/// Parse up to 19 digits (the max that can be stored in a 64-bit integer).
fn tryParse19Digits(stream: *FloatStream, x: *u64) void {
    while (x.* < min_19digit_int) {
        if (stream.scanDigit()) |digit| {
            x.* *%= 10;
            x.* +%= digit;
        } else {
            break;
        }
    }
}

/// Parse the scientific notation component of a float.
fn parseScientific(stream: *FloatStream) ?i64 {
    var exponent: i64 = 0;
    var negative = false;

    if (stream.first()) |c| {
        negative = c == '-';
        if (c == '-' or c == '+') {
            stream.advance(1);
        }
    }
    if (stream.firstIsDigit()) {
        while (stream.scanDigit()) |digit| {
            // no overflows here, saturate well before overflow
            if (exponent < 0x10000) {
                exponent = 10 * exponent + digit;
            }
        }

        return if (negative) -exponent else exponent;
    }

    return null;
}

/// Parse a partial, non-special floating point number.
///
/// This creates a representation of the float as the
/// significant digits and the decimal exponent.
fn parsePartialNumber(s: []const u8, negative: bool, n: *usize) ?Number {
    std.debug.assert(s.len != 0);
    var stream = FloatStream.init(s);

    // parse initial digits before dot
    var mantissa: u64 = 0;
    tryParseDigits(&stream, &mantissa);
    var int_end = stream.offset;
    var n_digits = @intCast(isize, stream.offset);

    // handle dot with the following digitis
    var exponent: i64 = 0;
    if (stream.firstIs('.')) {
        stream.advance(1);
        const marker = stream.offset;
        tryParse8Digits(&stream, &mantissa);
        tryParseDigits(&stream, &mantissa);

        const n_after_dot = stream.offset - marker;
        exponent = -@intCast(i64, n_after_dot);
        n_digits += @intCast(isize, n_after_dot);
    }

    if (n_digits == 0) {
        return null;
    }

    // handle scientific format
    var exp_number: i64 = 0;
    if (stream.firstIs2('e', 'E')) {
        stream.advance(1);
        exp_number = parseScientific(&stream) orelse return null;
        exponent += exp_number;
    }

    const len = stream.offset;
    n.* = len;

    // common case with not many digits
    if (n_digits <= 19) {
        return Number{
            .exponent = exponent,
            .mantissa = mantissa,
            .negative = negative,
            .many_digits = false,
        };
    }

    n_digits -= 19;
    var many_digits = false;
    stream.reset(); // re-parse from beginning
    while (stream.firstIs2('0', '.')) {
        // '0' = '.' + 2
        n_digits -= @intCast(isize, stream.firstUnchecked() -| ('0' - 1));
        stream.advance(1);
    }
    if (n_digits > 0) {
        // at this point we have more than 19 significant digits, let's try again
        many_digits = true;
        mantissa = 0;
        stream.reset();
        tryParse19Digits(&stream, &mantissa);

        exponent = blk: {
            if (mantissa >= min_19digit_int) {
                // big int
                break :blk @intCast(i64, int_end) - @intCast(i64, stream.offset);
            } else {
                // the next byte must be present and be '.'
                // We know this is true because we had more than 19
                // digits previously, so we overflowed a 64-bit integer,
                // but parsing only the integral digits produced less
                // than 19 digits. That means we must have a decimal
                // point, and at least 1 fractional digit.
                stream.advance(1);
                var marker = stream.offset;
                tryParse19Digits(&stream, &mantissa);
                break :blk @intCast(i64, marker) - @intCast(i64, stream.offset);
            }
        };
        // add back the explicit part
        exponent += exp_number;
    }

    return Number{
        .exponent = exponent,
        .mantissa = mantissa,
        .negative = negative,
        .many_digits = many_digits,
    };
}

pub fn parseNumber(s: []const u8, negative: bool) ?Number {
    var consumed: usize = 0;
    if (parsePartialNumber(s, negative, &consumed)) |number| {
        // must consume entire float (no trailing data)
        if (s.len == consumed) {
            return number;
        }
    }
    return null;
}

fn parsePartialInfOrNan(comptime T: type, s: []const u8, n: *usize) ?T {
    // inf/infinity; infxxx should only consume inf.
    if (std.ascii.startsWithIgnoreCase(s, "inf")) {
        n.* = 3;
        if (std.ascii.startsWithIgnoreCase(s[3..], "inity")) {
            n.* = 8;
        }
        return std.math.inf(T);
    }

    if (std.ascii.startsWithIgnoreCase(s, "nan")) {
        n.* = 3;
        return std.math.nan(T);
    }

    return null;
}

pub fn parseInfOrNan(comptime T: type, s: []const u8, negative: bool) ?T {
    var consumed: usize = 0;
    if (parsePartialInfOrNan(T, s, &consumed)) |special| {
        if (s.len == consumed) {
            if (negative) {
                return -1 * special;
            }
            return special;
        }
    }
    return null;
}
