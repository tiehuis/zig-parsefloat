An implementation of fmt.parseFloat for zig.

This is intended to be a robust, fast and accurate float parser to replace the
existing code in std.

For a detail on the methods used, see:
 - https://nigeltao.github.io/blog/2020/eisel-lemire.html
 - https://nigeltao.github.io/blog/2020/parse-number-f64-simple.html

A good corpus of test data can be found at:
 - https://github.com/nigeltao/parse-number-fxx-test-data

This is a fairly direct port of dec2flt found in the rust tree:
 - https://github.com/rust-lang/rust/tree/master/library/core/src/num/dec2flt

This was chosen for a few reasons, but primarily because the concepts map fairly
well to Zig and a lot of the work here has been backported to the reference C++
implementation.

# High-Level

The main entrypoint is `parseFloat(comptime T: type, s: []const u8) !T`.

This function will:
 1. Parse the number into mantissa/exponent/negative
    a. If the number was special (nan/inf), return immediately
    b. If the number could not be parsed, returns an error
 2. Attempt to convert via a fast path, where the mantissa/exponent is directly
    representable by a machine-sized float.
 3. If not succesful, attempt to convert using the eisel-lemire algorithm.
    This will work for ~99% of cases.
 4. If not succesful, convert using a big decimal type. This will always be
    work.

# Performance Testing

This repo vendors https://github.com/tiehuis/simple_fastfloat_benchmark.

```
cmake -B build simple_fastfloat_benchmark
cmake --build build
./simple_fastfloat_benchmark/run_bench.sh
```

If you make changes to the zig parseFloat function in this repo. Perform the
following to update the benchmark program.

```
./update_zig_ftoa_benchmark_lib # Update the vendored library
cmake --build build
./simple_fastfloat_benchmark/run_bench.sh
```


# TODO

Before merging, complete the following:

 - [x] Allow underscores according to zig spec in floating point literals
 - [x] support for hex-floats in parseFloat directly (currently uses
   parseHexFloat separate function).
 - [ ] Fix eisel-lemire algorithm for f16 (1 in 5 million test cases failing).
 - [x] Consider f128 support mechanism. Likely push back to a later commit.

# f128 support

Implemented in https://github.com/tiehuis/zig-parsefloat/commit/db7bfff803d000a781ca54f82b8f8b3f27ebbd19.
