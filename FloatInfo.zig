const std = @import("std");
const Self = @This();

// Minimum exponent that for a fast path case, or `-⌊(MANTISSA_EXPLICIT_BITS+1)/log2(5)⌋`
min_exponent_fast_path: comptime_int,

// Maximum exponent that for a fast path case, or `⌊(MANTISSA_EXPLICIT_BITS+1)/log2(5)⌋`
max_exponent_fast_path: comptime_int,

// Maximum exponent that can be represented for a disguised-fast path case.
// This is `MAX_EXPONENT_FAST_PATH + ⌊(MANTISSA_EXPLICIT_BITS+1)/log2(10)⌋`
max_exponent_fast_path_disguised: comptime_int,

// Maximum mantissa for the fast-path (`1 << 53` for f64).
max_mantissa_fast_path: comptime_int,

// Smallest decimal exponent for a non-zero value.
smallest_power_of_ten: comptime_int,

// Largest decimal exponent for a non-infinite value.
largest_power_of_ten: comptime_int,

// The number of bits in the significand, *excluding* the hidden bit.
mantissa_explicit_bits: comptime_int,

// Minimum exponent value `-(1 << (EXP_BITS - 1)) + 1`.
minimum_exponent: comptime_int,

// Round-to-even only happens for negative values of q
// when q ≥ −4 in the 64-bit case and when q ≥ −17 in
// the 32-bitcase.
//
// When q ≥ 0,we have that 5^q ≤ 2m+1. In the 64-bit case,we
// have 5^q ≤ 2m+1 ≤ 2^54 or q ≤ 23. In the 32-bit case,we have
// 5^q ≤ 2m+1 ≤ 2^25 or q ≤ 10.
//
// When q < 0, we have w ≥ (2m+1)×5^−q. We must have that w < 2^64
// so (2m+1)×5^−q < 2^64. We have that 2m+1 > 2^53 (64-bit case)
// or 2m+1 > 2^24 (32-bit case). Hence,we must have 2^53×5^−q < 2^64
// (64-bit) and 2^24×5^−q < 2^64 (32-bit). Hence we have 5^−q < 2^11
// or q ≥ −4 (64-bit case) and 5^−q < 2^40 or q ≥ −17 (32-bitcase).
//
// Thus we have that we only need to round ties to even when
// we have that q ∈ [−4,23](in the 64-bit case) or q∈[−17,10]
// (in the 32-bit case). In both cases,the power of five(5^|q|)
// fits in a 64-bit word.
min_exponent_round_to_even: comptime_int,
max_exponent_round_to_even: comptime_int,

// Largest exponent value `(1 << EXP_BITS) - 1`.
infinite_power: comptime_int,

// TODO: Compute based on derived properties instead of hardcoded structures.
pub fn from(comptime T: type) Self {
    return switch (T) {
        f16 => .{
            .min_exponent_fast_path = -4,
            .max_exponent_fast_path = 4,
            .max_exponent_fast_path_disguised = 7,
            .max_mantissa_fast_path = 2 << std.math.floatMantissaBits(T),

            .smallest_power_of_ten = -8, // 5.96046447753906250000000000000000000e-8F16;
            .largest_power_of_ten = 4,
            .mantissa_explicit_bits = std.math.floatMantissaBits(T),
            .minimum_exponent = -14,
            // w >= (2m+1) * 5^-q and w < 2^64
            // => 2m+1 > 2^9
            // => 2^9*5^-q < 2^64
            // => 5^-q < 2^55
            // => q >= -23
            .min_exponent_round_to_even = -23,
            // 5^q <= 2m+1 <= 2^8 or q <= 3
            .max_exponent_round_to_even = 3,
            .infinite_power = 0x1f,
        },
        f32 => .{
            .min_exponent_fast_path = -10,
            .max_exponent_fast_path = 10,
            .max_exponent_fast_path_disguised = 17,
            .max_mantissa_fast_path = 2 << std.math.floatMantissaBits(T),

            .smallest_power_of_ten = -65,
            .largest_power_of_ten = 38,
            .mantissa_explicit_bits = std.math.floatMantissaBits(T),
            .minimum_exponent = -127,
            .min_exponent_round_to_even = -17,
            .max_exponent_round_to_even = 10,
            .infinite_power = 0xff,
        },
        f64 => .{
            .min_exponent_fast_path = -22,
            .max_exponent_fast_path = 22,
            .max_exponent_fast_path_disguised = 37,
            .max_mantissa_fast_path = 2 << std.math.floatMantissaBits(T),

            .smallest_power_of_ten = -342,
            .largest_power_of_ten = 308,
            .mantissa_explicit_bits = std.math.floatMantissaBits(T),
            .minimum_exponent = -1023,
            .min_exponent_round_to_even = -4,
            .max_exponent_round_to_even = 23,
            .infinite_power = 0x7ff,
        },
        else => unreachable,
    };
}
