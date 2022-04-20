const std = @import("std");
const parseFloat = @import("parse_float.zig").parseFloat;

test "fmt.parseFloat" {
    const testing = std.testing;
    const expect = testing.expect;
    const expectEqual = testing.expectEqual;
    const approxEqAbs = std.math.approxEqAbs;
    const epsilon = 1e-7;

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

        // TODO: f128 nan differs during cast
        try expectEqual(@bitCast(Z, try parseFloat(T, "nAn")), @bitCast(Z, std.math.nan(T)));
        try expectEqual(try parseFloat(T, "inF"), std.math.inf(T));
        try expectEqual(try parseFloat(T, "-INF"), -std.math.inf(T));

        // TODO: support underscores
        //try expectEqual(try parseFloat(T, "0.4e0066999999999999999999999999999999999999999999999999999"), std.math.inf(T));
        //try expect(approxEqAbs(T, try parseFloat(T, "0_1_2_3_4_5_6.7_8_9_0_0_0e0_0_1_0"), @as(T, 123456.789000e10), epsilon));

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
