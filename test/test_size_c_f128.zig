// excludes zig_ftoa16..64. For testing u128-based mantissa internal representation.

const parseFloat = @import("parse_float").parseFloat;

export fn zig_ftoa128(s: [*]const u8, l: usize, result: *f128) c_int {
    result.* = parseFloat(f16, s[0..l]) catch return -1;
    return 0;
}
