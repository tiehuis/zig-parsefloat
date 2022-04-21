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
