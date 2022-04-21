const std = @import("std");
const parse = @import("parse.zig");
const parseNumber = parse.parseNumber;
const parseInfOrNan = parse.parseInfOrNan;
const convertFast = @import("convert_fast.zig").convertFast;
const convertEiselLemire = @import("convert_eisel_lemire.zig").convertEiselLemire;
const convertSlow = @import("convert_slow.zig").convertSlow;

const optimize = true;

pub const ParseFloatError = error{
    // input was empty
    Empty,
    // invalid float literal
    Invalid,
};

pub fn parseFloat(comptime T: type, s: []const u8) ParseFloatError!T {
    if (s.len == 0) {
        return error.Empty;
    }

    var i: usize = 0;
    const negative = s[i] == '-';
    if (s[i] == '-' or s[i] == '+') {
        i += 1;
    }
    if (s.len == i) {
        return error.Invalid;
    }

    const n = parse.parseNumber(s[i..], negative) orelse {
        return parse.parseInfOrNan(T, s[i..], negative) orelse error.Invalid;
    };

    if (convertFast(T, n)) |f| {
        return f;
    }

    if (optimize) {
        // If significant digits were truncated, then we can have rounding error
        // only if `mantissa + 1` produces a different result. We also avoid
        // redundantly using the Eisel-Lemire algorithm if it was unable to
        // correctly round on the first pass.
        if (convertEiselLemire(T, n.exponent, n.mantissa)) |bf| {
            if (!n.many_digits) {
                return bf.toFloat(T, n.negative);
            }
            if (convertEiselLemire(T, n.exponent, n.mantissa + 1)) |bf2| {
                if (bf.eql(bf2)) {
                    return bf.toFloat(T, n.negative);
                }
            }
        }
    }

    // Unable to correctly round the float using the Eisel-Lemire algorithm.
    // Fallback to a slower, but always correct algorithm.
    return convertSlow(T, s[i..]).toFloat(T, negative);
}
