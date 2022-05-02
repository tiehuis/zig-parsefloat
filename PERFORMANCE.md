This file outlines performance at specific commits in the project and provides
some detail on the impact various changes had on a runtime performance metric.

# commit: 7c0eb4d66e5a77883e5b36e031605f8a497a8c45

build: `zig build-exe -O ReleaseFast test_all_fxx_data.zig`

optimize = false    (fast-path + slow-path)

```
$ ./test_all_fxx_data
5296694/5296694 succeeded (0 fail)
________________________________________________________
Executed in   52.02 secs    fish           external
   usr time   51.89 secs    1.30 millis   51.89 secs
   sys time    0.05 secs    0.30 millis    0.05 secs
```

optimize = true     (fast-path + eisel-lemire + slow-path)

```
$ ./test_all_fxx_data
time ./test_all_fxx_data 
 | f16: 0000 33000000 3E60000000000000 2.98023223876953125E-8: found 0x1
5296693/5296694 succeeded (1 fail)

________________________________________________________
Executed in    2.54 secs    fish           external
   usr time    2.49 secs    1.29 millis    2.49 secs
   sys time    0.05 secs    0.30 millis    0.05 secs
```

# commit: 1cdbb5e2d6a33967a1255cd9a7066a0502a90c26

Added underscore handling. This does slow down parsing by ~10%. This is without
doing the separate scan since all test cases do not contain underscores.

No underscore handling (commit 7c0eb4d66e5a77883e5b36e031605f8a497a8c45)

```
$ time ./test_all_fxx_data
 | f16: 0000 33000000 3E60000000000000 2.98023223876953125E-8: found 0x1
5296693/5296694 succeeded (1 fail)

________________________________________________________
Executed in    2.49 secs    fish           external
   usr time    2.44 secs  864.00 micros    2.44 secs
   sys time    0.05 secs    0.00 micros    0.05 secs
```

With underscore handling:

```
$ time ./test_all_fxx_data
 | f16: 0000 33000000 3E60000000000000 2.98023223876953125E-8: found 0x1
5296693/5296694 succeeded (1 fail)

________________________________________________________
Executed in    2.74 secs    fish           external
   usr time    2.69 secs    0.00 micros    2.69 secs
   sys time    0.04 secs  924.00 micros    0.04 secs
```

# commit: 6f91666daf6e22f5528d48b8862d6891bada8898

build: `zig build-exe -O ReleaseFast test_all_fxx_data.zig`

```
time ./test_all_fxx_data
 | f16: 0000 33000000 3E60000000000000 2.98023223876953125E-8: found 0x1
5296693/5296694 succeeded (1 fail)

________________________________________________________
Executed in    2.81 secs    fish           external
   usr time    2.75 secs  848.00 micros    2.75 secs
   sys time    0.06 secs  204.00 micros    0.06 secs
```

Added initial hex-float parsing/conversion support. Note that these test cases
do not have any hex-float cases. We are simply testing that the changes do not
introduce unforeseen performance reductions in the common path.

```
time ./test_all_fxx_data
 | f16: 0000 33000000 3E60000000000000 2.98023223876953125E-8: found 0x1
5296693/5296694 succeeded (1 fail)

________________________________________________________
Executed in    2.76 secs    fish           external
   usr time    2.71 secs  821.00 micros    2.71 secs
   sys time    0.05 secs  201.00 micros    0.05 secs
```

# commit: f468fef30d5e8bd20d5cc6439fee0fb54e9e70b0

Fixed multi-digit scanning and applied to integer portion and not just
scientific.

## Before

```
$ time ./test_all_fxx_data
 | f16: 0000 33000000 3E60000000000000 2.98023223876953125E-8: found 0x1
5296693/5296694 succeeded (1 fail)

________________________________________________________
Executed in    2.69 secs    fish           external
   usr time    2.66 secs  611.00 micros    2.66 secs
   sys time    0.03 secs  117.00 micros    0.03 secs
```

## After

```
$ time ./test_all_fxx_data
 | f16: 0000 33000000 3E60000000000000 2.98023223876953125E-8: found 0x1
5296693/5296694 succeeded (1 fail)

________________________________________________________
Executed in    2.56 secs    fish           external
   usr time    2.50 secs  881.00 micros    2.50 secs
   sys time    0.06 secs  160.00 micros    0.06 secs
```

# commit: 410a5b4d715ee3ee32822bccbc37678977ea772d

New test-data was added with f128 bit representations. This means extracting
test data during the test_all_fxx_data programs' execution takes longer.

Following excludes testing f128 parseFloat (only string extraction).

```
| f16: 0000 33000000 3E60000000000000 3FE60000000000000000000000000000 2.98023223876953125E-8, found 0x1
5296693/5296694 succeeded (1 fail)

________________________________________________________
Executed in    4.55 secs    fish           external
   usr time    4.48 secs    0.00 millis    4.48 secs
   sys time    0.05 secs    1.47 millis    0.05 secs
```

# commit: 3f03583a30671508d9ba4d2c2b946c9d7cbe7a42

Perform toLower on exponent-check instead of checking two characters for
equality.


## before

```
$ time ./test_all_fxx_data
 | f16: 0000 33000000 3E60000000000000 3FE60000000000000000000000000000 2.98023223876953125E-8, found 0x1
5296693/5296694 succeeded (1 fail)

________________________________________________________
Executed in    4.46 secs    fish           external
   usr time    4.36 secs  597.00 micros    4.36 secs
   sys time    0.10 secs  175.00 micros    0.10 secs
```

## after

```
$ time ./test_all_fxx_data
 | f16: 0000 33000000 3E60000000000000 3FE60000000000000000000000000000 2.98023223876953125E-8, found 0x1
5296693/5296694 succeeded (1 fail)

________________________________________________________
Executed in    4.35 secs    fish           external
   usr time    4.27 secs  876.00 micros    4.27 secs
   sys time    0.07 secs  107.00 micros    0.07 secs
```

# commit: db7bfff803d000a781ca54f82b8f8b3f27ebbd19

Test full f128 using slow-path alongside f16, f32 and f64.

```
 | f16: 0000 33000000 3E60000000000000 3FE60000000000000000000000000000 2.98023223876953125E-8, found 0x1
5296693/5296694 succeeded (1 fail)

________________________________________________________
Executed in  641.67 secs    fish           external
   usr time  632.48 secs    1.05 millis  632.48 secs
   sys time    0.86 secs    0.19 millis    0.86 secs
```

Test f16, f32 and f64 without f128 (ensure no regression)

```
 | f16: 0000 33000000 3E60000000000000 3FE60000000000000000000000000000 2.98023223876953125E-8, found 0x1
5296693/5296694 succeeded (1 fail)

________________________________________________________
Executed in    4.52 secs    fish           external
   usr time    4.34 secs  986.00 micros    4.34 secs
   sys time    0.08 secs  178.00 micros    0.08 secs
```

# commit: b15406a0d2e18b50a4b62fceb5a6a3bb60ca5706

`simple_fastfloat_benchmark` results:

Note that we do a little bit more (such as hex-float parsing) and handle
underscores in our implementation. There is probably a little bit more
performance we can eek out regardless of this constraints, however.

```
./simple_fastfloat_benchmark/run_bench.sh
data/canada.txt
# parsing random numbers
available models (-m): uniform one_over_rand32 simple_uniform32 simple_int32 int_e_int simple_int64 bigint_int_dot_int big_ints 
model: generate random numbers uniformly in the interval [0.0,1.0]
volume: 100000 floats
volume = 2.09808 MB 
netlib                                  :   211.20 MB/s (+/- 3.5 %)    10.07 Mfloat/s      29.67 i/B   652.78 i/f (+/- 0.0 %)      0.18 bm/B     3.89 bm/f (+/- 0.3 %)     15.37 c/B   338.24 c/f (+/- 0.3 %)      1.93 i/c      3.40 GHz 
doubleconversion                        :   182.66 MB/s (+/- 3.8 %)     8.71 Mfloat/s      49.79 i/B  1095.44 i/f (+/- 0.0 %)      0.07 bm/B     1.62 bm/f (+/- 1.8 %)     17.78 c/B   391.13 c/f (+/- 0.6 %)      2.80 i/c      3.41 GHz 
strtod                                  :   138.79 MB/s (+/- 2.3 %)     6.61 Mfloat/s      50.78 i/B  1117.27 i/f (+/- 0.0 %)      0.12 bm/B     2.69 bm/f (+/- 0.5 %)     23.07 c/B   507.51 c/f (+/- 0.3 %)      2.20 i/c      3.36 GHz 
abseil                                  :   382.20 MB/s (+/- 4.8 %)    18.22 Mfloat/s      28.34 i/B   623.53 i/f (+/- 0.0 %)      0.02 bm/B     0.50 bm/f (+/- 0.4 %)      8.50 c/B   187.05 c/f (+/- 1.4 %)      3.33 i/c      3.41 GHz 
fastfloat                               :   817.11 MB/s (+/- 7.2 %)    38.95 Mfloat/s      13.14 i/B   289.07 i/f (+/- 0.0 %)      0.00 bm/B     0.01 bm/f (+/- 1.1 %)      4.08 c/B    89.85 c/f (+/- 1.1 %)      3.22 i/c      3.50 GHz 
zig_ftoa                                :   672.87 MB/s (+/- 7.7 %)    32.07 Mfloat/s      17.23 i/B   379.03 i/f (+/- 0.0 %)      0.00 bm/B     0.01 bm/f (+/- 0.8 %)      4.95 c/B   109.00 c/f (+/- 2.3 %)      3.48 i/c      3.50 GHz 
# You can also provide a filename (with the -f flag): it should contain one string per line corresponding to a number
data/mesh.txt
# parsing random numbers
available models (-m): uniform one_over_rand32 simple_uniform32 simple_int32 int_e_int simple_int64 bigint_int_dot_int big_ints 
model: generate random numbers uniformly in the interval [0.0,1.0]
volume: 100000 floats
volume = 2.09808 MB 
netlib                                  :   218.81 MB/s (+/- 4.2 %)    10.43 Mfloat/s      29.67 i/B   652.67 i/f (+/- 0.0 %)      0.16 bm/B     3.51 bm/f (+/- 0.6 %)     14.88 c/B   327.34 c/f (+/- 0.4 %)      1.99 i/c      3.41 GHz 
doubleconversion                        :   180.79 MB/s (+/- 2.8 %)     8.62 Mfloat/s      49.78 i/B  1095.07 i/f (+/- 0.0 %)      0.07 bm/B     1.62 bm/f (+/- 1.6 %)     17.75 c/B   390.61 c/f (+/- 0.5 %)      2.80 i/c      3.37 GHz 
strtod                                  :   139.43 MB/s (+/- 2.9 %)     6.65 Mfloat/s      50.81 i/B  1117.73 i/f (+/- 0.0 %)      0.12 bm/B     2.70 bm/f (+/- 0.7 %)     23.04 c/B   506.82 c/f (+/- 0.4 %)      2.21 i/c      3.37 GHz 
abseil                                  :   389.39 MB/s (+/- 6.4 %)    18.56 Mfloat/s      28.34 i/B   623.50 i/f (+/- 0.0 %)      0.02 bm/B     0.50 bm/f (+/- 0.2 %)      8.44 c/B   185.58 c/f (+/- 2.0 %)      3.36 i/c      3.44 GHz 
fastfloat                               :   818.62 MB/s (+/- 7.0 %)    39.02 Mfloat/s      13.14 i/B   289.07 i/f (+/- 0.0 %)      0.00 bm/B     0.01 bm/f (+/- 1.8 %)      4.08 c/B    89.70 c/f (+/- 1.1 %)      3.22 i/c      3.50 GHz 
zig_ftoa                                :   663.83 MB/s (+/- 6.9 %)    31.64 Mfloat/s      17.23 i/B   379.03 i/f (+/- 0.0 %)      0.00 bm/B     0.01 bm/f (+/- 0.6 %)      4.95 c/B   109.00 c/f (+/- 2.3 %)      3.48 i/c      3.45 GHz 
# You can also provide a filename (with the -f flag): it should contain one string per line corresponding to a number
-m uniform
# parsing random numbers
available models (-m): uniform one_over_rand32 simple_uniform32 simple_int32 int_e_int simple_int64 bigint_int_dot_int big_ints 
model: generate random numbers uniformly in the interval [0.0,1.0]
volume: 100000 floats
volume = 2.09808 MB 
netlib                                  :   208.52 MB/s (+/- 4.4 %)     9.94 Mfloat/s      29.67 i/B   652.76 i/f (+/- 0.0 %)      0.18 bm/B     3.87 bm/f (+/- 0.3 %)     15.35 c/B   337.60 c/f (+/- 0.4 %)      1.93 i/c      3.36 GHz 
doubleconversion                        :   179.46 MB/s (+/- 3.3 %)     8.55 Mfloat/s      49.78 i/B  1095.16 i/f (+/- 0.0 %)      0.07 bm/B     1.62 bm/f (+/- 1.6 %)     17.73 c/B   389.95 c/f (+/- 0.6 %)      2.81 i/c      3.34 GHz 
strtod                                  :   138.37 MB/s (+/- 3.1 %)     6.59 Mfloat/s      50.80 i/B  1117.57 i/f (+/- 0.0 %)      0.12 bm/B     2.71 bm/f (+/- 0.2 %)     23.08 c/B   507.72 c/f (+/- 0.3 %)      2.20 i/c      3.35 GHz 
abseil                                  :   383.26 MB/s (+/- 5.5 %)    18.27 Mfloat/s      28.34 i/B   623.47 i/f (+/- 0.0 %)      0.02 bm/B     0.50 bm/f (+/- 0.4 %)      8.48 c/B   186.48 c/f (+/- 1.6 %)      3.34 i/c      3.41 GHz 
fastfloat                               :   829.36 MB/s (+/- 9.3 %)    39.53 Mfloat/s      13.14 i/B   289.08 i/f (+/- 0.0 %)      0.00 bm/B     0.01 bm/f (+/- 1.6 %)      4.08 c/B    89.79 c/f (+/- 1.0 %)      3.22 i/c      3.55 GHz 
zig_ftoa                                :   649.77 MB/s (+/- 7.1 %)    30.97 Mfloat/s      17.23 i/B   379.03 i/f (+/- 0.0 %)      0.00 bm/B     0.01 bm/f (+/- 0.8 %)      4.99 c/B   109.70 c/f (+/- 2.5 %)      3.46 i/c      3.40 GHz 
# You can also provide a filename (with the -f flag): it should contain one string per line corresponding to a number
-m uniform -c
# parsing random numbers
available models (-m): uniform one_over_rand32 simple_uniform32 simple_int32 int_e_int simple_int64 bigint_int_dot_int big_ints 
model: generate random numbers uniformly in the interval [0.0,1.0]
concise (using as few digits as possible)
volume: 100000 floats
volume = 1.74253 MB 
netlib                                  :   184.74 MB/s (+/- 5.0 %)    10.60 Mfloat/s      32.61 i/B   595.77 i/f (+/- 0.0 %)      0.21 bm/B     3.78 bm/f (+/- 0.2 %)     17.48 c/B   319.46 c/f (+/- 0.5 %)      1.86 i/c      3.39 GHz 
doubleconversion                        :   169.17 MB/s (+/- 5.3 %)     9.71 Mfloat/s      53.91 i/B   985.11 i/f (+/- 0.0 %)      0.09 bm/B     1.62 bm/f (+/- 1.0 %)     19.07 c/B   348.36 c/f (+/- 1.1 %)      2.83 i/c      3.38 GHz 
strtod                                  :   118.02 MB/s (+/- 5.1 %)     6.77 Mfloat/s      56.17 i/B  1026.24 i/f (+/- 0.0 %)      0.18 bm/B     3.34 bm/f (+/- 0.4 %)     27.22 c/B   497.28 c/f (+/- 0.6 %)      2.06 i/c      3.37 GHz 
abseil                                  :   301.85 MB/s (+/- 5.2 %)    17.32 Mfloat/s      31.24 i/B   570.84 i/f (+/- 0.0 %)      0.05 bm/B     0.96 bm/f (+/- 0.3 %)     10.56 c/B   192.97 c/f (+/- 1.4 %)      2.96 i/c      3.34 GHz 
fastfloat                               :   719.13 MB/s (+/- 8.5 %)    41.27 Mfloat/s      11.46 i/B   209.37 i/f (+/- 0.0 %)      0.03 bm/B     0.63 bm/f (+/- 0.5 %)      4.55 c/B    83.14 c/f (+/- 2.2 %)      2.52 i/c      3.43 GHz 
zig_ftoa                                :   569.86 MB/s (+/- 8.4 %)    32.70 Mfloat/s      15.25 i/B   278.57 i/f (+/- 0.0 %)      0.03 bm/B     0.60 bm/f (+/- 0.3 %)      5.75 c/B   105.15 c/f (+/- 1.2 %)      2.65 i/c      3.44 GHz 
# You can also provide a filename (with the -f flag): it should contain one string per line corresponding to a number
-m simple_uniform32
# parsing random numbers
available models (-m): uniform one_over_rand32 simple_uniform32 simple_int32 int_e_int simple_int64 bigint_int_dot_int big_ints 
model: rand() / 0xFFFFFFFF 
volume: 100000 floats
volume = 2.09808 MB 
netlib                                  :   215.36 MB/s (+/- 4.9 %)    10.26 Mfloat/s      29.67 i/B   652.78 i/f (+/- 0.0 %)      0.16 bm/B     3.52 bm/f (+/- 0.5 %)     14.94 c/B   328.65 c/f (+/- 0.5 %)      1.99 i/c      3.37 GHz 
doubleconversion                        :   182.86 MB/s (+/- 6.7 %)     8.72 Mfloat/s      49.79 i/B  1095.40 i/f (+/- 0.0 %)      0.07 bm/B     1.61 bm/f (+/- 1.7 %)     17.77 c/B   390.92 c/f (+/- 0.8 %)      2.80 i/c      3.41 GHz 
strtod                                  :   138.16 MB/s (+/- 4.4 %)     6.58 Mfloat/s      50.80 i/B  1117.66 i/f (+/- 0.0 %)      0.12 bm/B     2.70 bm/f (+/- 0.3 %)     23.09 c/B   507.93 c/f (+/- 0.7 %)      2.20 i/c      3.34 GHz 
abseil                                  :   374.27 MB/s (+/- 6.3 %)    17.84 Mfloat/s      28.34 i/B   623.48 i/f (+/- 0.0 %)      0.02 bm/B     0.50 bm/f (+/- 0.3 %)      8.58 c/B   188.75 c/f (+/- 1.2 %)      3.30 i/c      3.37 GHz 
fastfloat                               :   811.68 MB/s (+/- 8.0 %)    38.69 Mfloat/s      13.14 i/B   289.07 i/f (+/- 0.0 %)      0.00 bm/B     0.01 bm/f (+/- 0.9 %)      4.08 c/B    89.84 c/f (+/- 1.5 %)      3.22 i/c      3.48 GHz 
zig_ftoa                                :   666.71 MB/s (+/- 8.7 %)    31.78 Mfloat/s      17.23 i/B   379.03 i/f (+/- 0.0 %)      0.00 bm/B     0.01 bm/f (+/- 0.7 %)      4.95 c/B   108.98 c/f (+/- 3.2 %)      3.48 i/c      3.46 GHz 
# You can also provide a filename (with the -f flag): it should contain one string per line corresponding to a number
-m simple_uniform32 -c
# parsing random numbers
available models (-m): uniform one_over_rand32 simple_uniform32 simple_int32 int_e_int simple_int64 bigint_int_dot_int big_ints 
model: rand() / 0xFFFFFFFF 
concise (using as few digits as possible)
volume: 100000 floats
volume = 1.74219 MB 
netlib                                  :   185.19 MB/s (+/- 5.5 %)    10.63 Mfloat/s      32.60 i/B   595.57 i/f (+/- 0.0 %)      0.21 bm/B     3.75 bm/f (+/- 0.2 %)     17.41 c/B   318.11 c/f (+/- 0.7 %)      1.87 i/c      3.38 GHz 
doubleconversion                        :   165.67 MB/s (+/- 4.7 %)     9.51 Mfloat/s      53.88 i/B   984.33 i/f (+/- 0.0 %)      0.09 bm/B     1.67 bm/f (+/- 1.2 %)     19.19 c/B   350.54 c/f (+/- 1.3 %)      2.81 i/c      3.33 GHz 
strtod                                  :   117.63 MB/s (+/- 3.7 %)     6.75 Mfloat/s      56.20 i/B  1026.65 i/f (+/- 0.0 %)      0.18 bm/B     3.33 bm/f (+/- 0.3 %)     27.17 c/B   496.33 c/f (+/- 0.6 %)      2.07 i/c      3.35 GHz 
abseil                                  :   312.82 MB/s (+/- 5.8 %)    17.96 Mfloat/s      31.24 i/B   570.78 i/f (+/- 0.0 %)      0.05 bm/B     0.96 bm/f (+/- 0.3 %)     10.50 c/B   191.85 c/f (+/- 1.0 %)      2.98 i/c      3.44 GHz 
fastfloat                               :   746.05 MB/s (+/- 8.1 %)    42.82 Mfloat/s      11.47 i/B   209.48 i/f (+/- 0.0 %)      0.03 bm/B     0.62 bm/f (+/- 0.4 %)      4.47 c/B    81.73 c/f (+/- 2.2 %)      2.56 i/c      3.50 GHz 
zig_ftoa                                :   585.53 MB/s (+/- 7.1 %)    33.61 Mfloat/s      15.26 i/B   278.77 i/f (+/- 0.0 %)      0.03 bm/B     0.60 bm/f (+/- 0.2 %)      5.69 c/B   103.93 c/f (+/- 1.0 %)      2.68 i/c      3.49 GHz 
# You can also provide a filename (with the -f flag): it should contain one string per line corresponding to a number
-m simple_int32
# parsing random numbers
available models (-m): uniform one_over_rand32 simple_uniform32 simple_int32 int_e_int simple_int64 bigint_int_dot_int big_ints 
model: rand()
volume: 100000 floats
volume = 0.928987 MB 
netlib                                  :   454.22 MB/s (+/- 6.6 %)    48.89 Mfloat/s      22.95 i/B   223.56 i/f (+/- 0.0 %)      0.04 bm/B     0.38 bm/f (+/- 0.5 %)      7.35 c/B    71.58 c/f (+/- 0.7 %)      3.12 i/c      3.50 GHz 
doubleconversion                        :   215.39 MB/s (+/- 6.1 %)    23.19 Mfloat/s      52.73 i/B   513.67 i/f (+/- 0.0 %)      0.04 bm/B     0.37 bm/f (+/- 0.8 %)     15.39 c/B   149.91 c/f (+/- 0.5 %)      3.43 i/c      3.48 GHz 
strtod                                  :   167.54 MB/s (+/- 5.7 %)    18.03 Mfloat/s      61.78 i/B   601.83 i/f (+/- 0.0 %)      0.02 bm/B     0.23 bm/f (+/- 0.1 %)     19.52 c/B   190.15 c/f (+/- 1.4 %)      3.17 i/c      3.43 GHz 
abseil                                  :   224.65 MB/s (+/- 6.5 %)    24.18 Mfloat/s      44.16 i/B   430.15 i/f (+/- 0.0 %)      0.02 bm/B     0.23 bm/f (+/- 0.3 %)     14.70 c/B   143.24 c/f (+/- 1.3 %)      3.00 i/c      3.46 GHz 
fastfloat                               :   701.83 MB/s (+/- 6.5 %)    75.55 Mfloat/s      12.76 i/B   124.28 i/f (+/- 0.0 %)      0.03 bm/B     0.25 bm/f (+/- 2.1 %)      4.76 c/B    46.34 c/f (+/- 0.9 %)      2.68 i/c      3.50 GHz 
zig_ftoa                                :   525.32 MB/s (+/- 8.0 %)    56.55 Mfloat/s      17.98 i/B   175.12 i/f (+/- 0.0 %)      0.02 bm/B     0.23 bm/f (+/- 2.5 %)      6.35 c/B    61.87 c/f (+/- 2.1 %)      2.83 i/c      3.50 GHz 
# You can also provide a filename (with the -f flag): it should contain one string per line corresponding to a number
```
