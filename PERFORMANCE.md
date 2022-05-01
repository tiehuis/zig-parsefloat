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
