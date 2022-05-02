const parseFloat = @import("parse_float").parseFloat;

export fn zig_ftoa16(s: [*]const u8, l: usize, result: *f16) c_int {
    result.* = parseFloat(f16, s[0..l]) catch return -1;
    return 0;
}

export fn zig_ftoa32(s: [*]const u8, l: usize, result: *f32) c_int {
    result.* = parseFloat(f32, s[0..l]) catch return -1;
    return 0;
}

export fn zig_ftoa64(s: [*]const u8, l: usize, result: *f64) c_int {
    result.* = parseFloat(f64, s[0..l]) catch return -1;
    return 0;
}

export fn zig_ftoa128(s: [*]const u8, l: usize, result: *f128) c_int {
    result.* = parseFloat(f128, s[0..l]) catch return -1;
    return 0;
}
