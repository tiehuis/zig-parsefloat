const std = @import("std");
const parseFloat = @import("parse_float.zig").parseFloat;
//const parseFloat = std.fmt.parseFloat;

const check_f16 = true;
const check_f32 = true;
const check_f64 = true;
const check_f128 = true;

// f16 f32 f64 string_repr
const TestCase = struct {
    f16_bits: u16,
    f32_bits: u32,
    f64_bits: u64,
    f128_bits: u128,
    float_string: []const u8,
    line: [max_line_length]u8,
    line_len: usize,
};

const max_line_length = 1024 * 1024;

pub fn scanLine(reader: anytype, testcase: *TestCase) !?*TestCase {
    if (try reader.readUntilDelimiterOrEof(testcase.line[0..], '\n')) |line| {
        var it = std.mem.tokenize(u8, line, " ");
        testcase.line_len = line.len;

        testcase.f16_bits = try std.fmt.parseInt(u16, it.next().?, 16);
        testcase.f32_bits = try std.fmt.parseInt(u32, it.next().?, 16);
        testcase.f64_bits = try std.fmt.parseInt(u64, it.next().?, 16);
        testcase.f128_bits = try std.fmt.parseInt(u128, it.next().?, 16);
        testcase.float_string = it.next().?; // testcase.line is stored with same lifetime as testcase.float_string

        return testcase;
    }

    // eof
    return null;
}

pub fn main() !void {
    const file_list = [_][]const u8{
        "parse-number-fxx-test-data/data/exhaustive-float16.txt",
        "parse-number-fxx-test-data/data/freetype-2-7.txt",
        "parse-number-fxx-test-data/data/google-double-conversion.txt",
        "parse-number-fxx-test-data/data/google-wuffs.txt",
        "parse-number-fxx-test-data/data/ibm-fpgen.txt",
        "parse-number-fxx-test-data/data/lemire-fast-double-parser.txt",
        "parse-number-fxx-test-data/data/more-test-cases.txt",
        "parse-number-fxx-test-data/data/remyoudompheng-fptest-0.txt",
        "parse-number-fxx-test-data/data/remyoudompheng-fptest-1.txt",
        "parse-number-fxx-test-data/data/remyoudompheng-fptest-2.txt",
        "parse-number-fxx-test-data/data/remyoudompheng-fptest-3.txt",
        "parse-number-fxx-test-data/data/tencent-rapidjson.txt",
        "parse-number-fxx-test-data/data/ulfjack-ryu.txt",
    };

    // TODO: relative to this script
    var cwd = std.fs.cwd();

    // pre-open all files to confirm they exist
    for (file_list) |file| {
        var f = try cwd.openFile(file, .{ .mode = .read_only });
        f.close();
    }

    var count: usize = 0;
    var fail: usize = 0;

    // data format is [f16-bits] [f32-bits] [f64-bits] [string-to-parse]
    for (file_list) |file| {
        var f = try cwd.openFile(file, .{ .mode = .read_only });
        defer f.close();
        var buf_reader = std.io.bufferedReader(f.reader());
        const stream = buf_reader.reader();

        var tc: TestCase = undefined;
        while (try scanLine(stream, &tc)) |_| {
            var failure = false;
            const tc_raw = tc.line[0..tc.line_len];

            // All passing using fast then slow (not eisel-lemire)
            if (check_f16) {
                const f16_result = @bitCast(u16, try parseFloat(f16, tc.float_string));
                if (tc.f16_bits != f16_result) {
                    std.debug.print(" | f16: {s}, found 0x{x}\n", .{ tc_raw, f16_result });
                    failure = true;
                }
            }

            if (check_f32) {
                const f32_result = @bitCast(u32, try parseFloat(f32, tc.float_string));
                if (tc.f32_bits != f32_result) {
                    std.debug.print(" | f32: {s}, found 0x{x}\n", .{ tc_raw, f32_result });
                    failure = true;
                }
            }

            if (check_f64) {
                const f64_result = @bitCast(u64, try parseFloat(f64, tc.float_string));
                if (tc.f64_bits != f64_result) {
                    std.debug.print(" | f64: {s}, found 0x{x}\n", .{ tc_raw, f64_result });
                    failure = true;
                }
            }

            if (check_f128) {
                const f128_result = @bitCast(u128, try parseFloat(f128, tc.float_string));
                if (tc.f128_bits != f128_result) {
                    std.debug.print(" | f128: {s}, found 0x{x}\n", .{ tc_raw, f128_result });
                    failure = true;
                }
            }

            if (failure) {
                fail += 1;
            }
            count += 1;
        }
    }

    std.debug.print("{}/{} succeeded ({} fail)\n", .{ count - fail, count, fail });
}
