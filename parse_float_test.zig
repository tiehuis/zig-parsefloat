const std = @import("std");
const math = std.math;
const parseFloat = @import("parse_float.zig").parseFloat;

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;
const expectError = testing.expectError;
const approxEqAbs = std.math.approxEqAbs;
const epsilon = 1e-7;

test "fmt.parseFloat" {
    // TODO
    //try expectEqual(@as(f16, 0), try parseFloat(f16, "2.98023223876953125E-8"));

    // TODO: f128
    inline for ([_]type{ f16, f32, f64 }) |T| {
        const Z = std.meta.Int(.unsigned, @typeInfo(T).Float.bits);

        try testing.expectError(error.Empty, parseFloat(T, ""));
        try testing.expectError(error.Invalid, parseFloat(T, "   1"));
        try testing.expectError(error.Invalid, parseFloat(T, "1abc"));
        try testing.expectError(error.Invalid, parseFloat(T, "+"));
        try testing.expectError(error.Invalid, parseFloat(T, "-"));

        try expectEqual(try parseFloat(T, "0"), 0.0);
        try expectEqual(try parseFloat(T, "0"), 0.0);
        try expectEqual(try parseFloat(T, "+0"), 0.0);
        try expectEqual(try parseFloat(T, "-0"), 0.0);

        try expectEqual(try parseFloat(T, "0e0"), 0);
        try expectEqual(try parseFloat(T, "2e3"), 2000.0);
        try expectEqual(try parseFloat(T, "1e0"), 1.0);
        try expectEqual(try parseFloat(T, "-2e3"), -2000.0);
        try expectEqual(try parseFloat(T, "-1e0"), -1.0);
        try expectEqual(try parseFloat(T, "1.234e3"), 1234);

        try expect(approxEqAbs(T, try parseFloat(T, "3.141"), 3.141, epsilon));
        try expect(approxEqAbs(T, try parseFloat(T, "-3.141"), -3.141, epsilon));

        try expectEqual(try parseFloat(T, "1e-700"), 0);
        try expectEqual(try parseFloat(T, "1e+700"), std.math.inf(T));

        try expectEqual(@bitCast(Z, try parseFloat(T, "nAn")), @bitCast(Z, std.math.nan(T)));
        try expectEqual(try parseFloat(T, "inF"), std.math.inf(T));
        try expectEqual(try parseFloat(T, "-INF"), -std.math.inf(T));

        try expectEqual(try parseFloat(T, "0.4e0066999999999999999999999999999999999999999999999999999"), std.math.inf(T));

        try expect(approxEqAbs(T, try parseFloat(T, "0_1_2_3_4_5_6.7_8_9_0_0_0e0_0_1_0"), @as(T, 123456.789000e10), epsilon));
        // underscore rule is simple and reduces to "can only occur between two digits" and multiple are not supported.
        try expectError(error.Invalid, parseFloat(T, "0123456.789000e_0010")); // cannot occur immediately after exponent
        try expectError(error.Invalid, parseFloat(T, "_0123456.789000e0010")); // cannot occur before any digits
        try expectError(error.Invalid, parseFloat(T, "0__123456.789000e_0010")); // cannot occur twice in a row
        try expectError(error.Invalid, parseFloat(T, "0123456_.789000e0010")); // cannot occur before decimal point
        try expectError(error.Invalid, parseFloat(T, "0123456.789000e0010_")); // cannot occur at end of number

        if (T != f16) {
            try expect(approxEqAbs(T, try parseFloat(T, "1e-2"), 0.01, epsilon));
            try expect(approxEqAbs(T, try parseFloat(T, "1234e-2"), 12.34, epsilon));

            try expect(approxEqAbs(T, try parseFloat(T, "123142.1"), 123142.1, epsilon));
            try expect(approxEqAbs(T, try parseFloat(T, "-123142.1124"), @as(T, -123142.1124), epsilon));
            try expect(approxEqAbs(T, try parseFloat(T, "0.7062146892655368"), @as(T, 0.7062146892655368), epsilon));
            try expect(approxEqAbs(T, try parseFloat(T, "2.71828182845904523536"), @as(T, 2.718281828459045), epsilon));
        }
    }
}

test "hex.special" {
    try testing.expect(math.isNan(try parseFloat(f32, "nAn")));
    try testing.expect(math.isPositiveInf(try parseFloat(f32, "iNf")));
    try testing.expect(math.isPositiveInf(try parseFloat(f32, "+Inf")));
    try testing.expect(math.isNegativeInf(try parseFloat(f32, "-iNf")));
}
test "hex.zero" {
    try testing.expectEqual(@as(f32, 0.0), try parseFloat(f32, "0x0"));
    try testing.expectEqual(@as(f32, 0.0), try parseFloat(f32, "-0x0"));
    try testing.expectEqual(@as(f32, 0.0), try parseFloat(f32, "0x0p42"));
    try testing.expectEqual(@as(f32, 0.0), try parseFloat(f32, "-0x0.00000p42"));
    try testing.expectEqual(@as(f32, 0.0), try parseFloat(f32, "0x0.00000p666"));
}

test "hex.f16" {
    try testing.expectEqual(try parseFloat(f16, "0x1p0"), 1.0);
    try testing.expectEqual(try parseFloat(f16, "-0x1p-1"), -0.5);
    try testing.expectEqual(try parseFloat(f16, "0x10p+10"), 16384.0);
    try testing.expectEqual(try parseFloat(f16, "0x10p-10"), 0.015625);
    // Max normalized value.
    try testing.expectEqual(try parseFloat(f16, "0x1.ffcp+15"), math.floatMax(f16));
    try testing.expectEqual(try parseFloat(f16, "-0x1.ffcp+15"), -math.floatMax(f16));
    // Min normalized value.
    try testing.expectEqual(try parseFloat(f16, "0x1p-14"), math.floatMin(f16));
    try testing.expectEqual(try parseFloat(f16, "-0x1p-14"), -math.floatMin(f16));
    // Min denormal value.
    try testing.expectEqual(try parseFloat(f16, "0x1p-24"), math.floatTrueMin(f16));
    try testing.expectEqual(try parseFloat(f16, "-0x1p-24"), -math.floatTrueMin(f16));
}

test "hex.f32" {
    try testing.expectEqual(try parseFloat(f32, "0x1p0"), 1.0);
    try testing.expectEqual(try parseFloat(f32, "-0x1p-1"), -0.5);
    try testing.expectEqual(try parseFloat(f32, "0x10p+10"), 16384.0);
    try testing.expectEqual(try parseFloat(f32, "0x10p-10"), 0.015625);
    try testing.expectEqual(try parseFloat(f32, "0x0.ffffffp128"), 0x0.ffffffp128);
    try testing.expectEqual(try parseFloat(f32, "0x0.1234570p-125"), 0x0.1234570p-125);
    // Max normalized value.
    try testing.expectEqual(try parseFloat(f32, "0x1.fffffeP+127"), math.floatMax(f32));
    try testing.expectEqual(try parseFloat(f32, "-0x1.fffffeP+127"), -math.floatMax(f32));
    // Min normalized value.
    try testing.expectEqual(try parseFloat(f32, "0x1p-126"), math.floatMin(f32));
    try testing.expectEqual(try parseFloat(f32, "-0x1p-126"), -math.floatMin(f32));
    // Min denormal value.
    try testing.expectEqual(try parseFloat(f32, "0x1P-149"), math.floatTrueMin(f32));
    try testing.expectEqual(try parseFloat(f32, "-0x1P-149"), -math.floatTrueMin(f32));
}

test "hex.f64" {
    try testing.expectEqual(try parseFloat(f64, "0x1p0"), 1.0);
    try testing.expectEqual(try parseFloat(f64, "-0x1p-1"), -0.5);
    try testing.expectEqual(try parseFloat(f64, "0x10p+10"), 16384.0);
    try testing.expectEqual(try parseFloat(f64, "0x10p-10"), 0.015625);
    // Max normalized value.
    try testing.expectEqual(try parseFloat(f64, "0x1.fffffffffffffp+1023"), math.floatMax(f64));
    try testing.expectEqual(try parseFloat(f64, "-0x1.fffffffffffffp1023"), -math.floatMax(f64));
    // Min normalized value.
    try testing.expectEqual(try parseFloat(f64, "0x1p-1022"), math.floatMin(f64));
    try testing.expectEqual(try parseFloat(f64, "-0x1p-1022"), -math.floatMin(f64));
    // Min denormalized value.
    //try testing.expectEqual(try parseFloat(f64, "0x1p-1074"), math.floatTrueMin(f64));
    try testing.expectEqual(try parseFloat(f64, "-0x1p-1074"), -math.floatTrueMin(f64));
}
test "hex.f128" {
    try testing.expectEqual(try parseFloat(f128, "0x1p0"), 1.0);
    try testing.expectEqual(try parseFloat(f128, "-0x1p-1"), -0.5);
    try testing.expectEqual(try parseFloat(f128, "0x10p+10"), 16384.0);
    try testing.expectEqual(try parseFloat(f128, "0x10p-10"), 0.015625);
    // Max normalized value.
    try testing.expectEqual(try parseFloat(f128, "0xf.fffffffffffffffffffffffffff8p+16380"), math.floatMax(f128));
    try testing.expectEqual(try parseFloat(f128, "-0xf.fffffffffffffffffffffffffff8p+16380"), -math.floatMax(f128));
    // Min normalized value.
    try testing.expectEqual(try parseFloat(f128, "0x1p-16382"), math.floatMin(f128));
    try testing.expectEqual(try parseFloat(f128, "-0x1p-16382"), -math.floatMin(f128));
    // // Min denormalized value.
    try testing.expectEqual(try parseFloat(f128, "0x1p-16494"), math.floatTrueMin(f128));
    try testing.expectEqual(try parseFloat(f128, "-0x1p-16494"), -math.floatTrueMin(f128));

    // TODO: We are performing round-to-even. Previous behavior was round-up.
    // try testing.expectEqual(try parseFloat(f128, "0x1.edcb34a235253948765432134674fp-1"), 0x1.edcb34a235253948765432134674fp-1);
}
