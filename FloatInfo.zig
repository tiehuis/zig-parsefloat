const std = @import("std");
const Self = @This();

min_exponent: comptime_int,
max_exponent: comptime_int,
max_exponent_disguised: comptime_int,
max_mantissa: comptime_int,
smallest_power_of_ten: comptime_int,
largest_power_of_ten: comptime_int,
mantissa_explicit_bits: comptime_int,
minimum_exponent: comptime_int,
min_exponent_round_to_even: comptime_int,
max_exponent_round_to_even: comptime_int,
infinite_power: comptime_int,

pub fn from(comptime T: type) Self {
    return switch (T) {
        f16 => .{
            // TODO: Compute based on derived properties instead of hardcoded structures.
            .min_exponent = -4,
            .max_exponent = 4,
            .max_exponent_disguised = 7,
            .max_mantissa = 2 << std.math.floatMantissaBits(T),

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
            .min_exponent = -10,
            .max_exponent = 10,
            .max_exponent_disguised = 17,
            .max_mantissa = 2 << std.math.floatMantissaBits(T),

            .smallest_power_of_ten = -65,
            .largest_power_of_ten = 38,
            .mantissa_explicit_bits = std.math.floatMantissaBits(T),
            .minimum_exponent = -127,
            .min_exponent_round_to_even = -17,
            .max_exponent_round_to_even = 10,
            .infinite_power = 0xff,
        },
        f64 => .{
            .min_exponent = -22,
            .max_exponent = 22,
            .max_exponent_disguised = 37,
            .max_mantissa = 2 << std.math.floatMantissaBits(T),

            .smallest_power_of_ten = -342,
            .largest_power_of_ten = 308,
            .mantissa_explicit_bits = std.math.floatMantissaBits(T),
            .minimum_exponent = -1023,
            .min_exponent_round_to_even = -4,
            .max_exponent_round_to_even = 23,
            .infinite_power = 0x7ff,
        },
        f128 => .{
            .min_exponent = -48,
            .max_exponent = 48,
            .max_exponent_disguised = 82,
            .max_mantissa = 2 << std.math.floatMantissaBits(T),
            // TODO: other information for required for eisel-lemire
        },
        else => @compileError("unsupported float type for eisel-lemire algorithm"),
    };
}
