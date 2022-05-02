This file outlines code-size at specific commits in the project and provides
some detail on the impact various changes had on the size of the resulting code.

See `test/` directory and the `build` script for details.

# commit: 14ed521f656bfa21f3c127a7073e8526aae44a5c

Summary is size of the new library is a fair amount larger than the existing
(fxx_std). This however is not too surprising since the old didn't accurately
convert all values and is an order of magnitude slower (for f64 or smaller).


## `zig build-lib -O ReleaseFast --strip`

```
libtest_size_c_f128.a
    FILE SIZE        VM SIZE
 --------------  --------------
  34.7%  13.4Ki  47.1%  13.3Ki    .rodata
  23.9%  9.25Ki  32.5%  9.19Ki    .text
  15.0%  5.80Ki  20.3%  5.73Ki    .rodata.str1.1
   9.3%  3.60Ki   0.0%       0    .symtab
   7.9%  3.06Ki   0.0%       0    .rela.rodata
   5.7%  2.20Ki   0.0%       0    .strtab
   1.9%     736   0.0%       0    .rela.text
   0.6%     254   0.0%       0    [AR Headers]
   0.5%     192   0.0%       0    [ELF Headers]
   0.2%      80   0.1%      16    .rodata.cst16
   0.2%      76   0.0%      12    .rodata.cst4
   0.1%      20   0.0%       0    [AR Symbol Table]
   0.0%       9   0.0%       0    [Unmapped]
 100.0%  38.6Ki 100.0%  28.3Ki    TOTAL
libtest_size_c_f64.a
    FILE SIZE        VM SIZE
 --------------  --------------
  44.1%  25.3Ki  56.4%  25.2Ki    .text
  23.9%  13.7Ki  30.5%  13.6Ki    .rodata
  10.1%  5.80Ki  12.8%  5.73Ki    .rodata.str1.1
   7.1%  4.07Ki   0.0%       0    .symtab
   5.3%  3.06Ki   0.0%       0    .rela.rodata
   4.4%  2.55Ki   0.0%       0    .strtab
   3.5%  2.01Ki   0.0%       0    .rela.text
   0.4%     252   0.0%       0    [AR Headers]
   0.3%     192   0.0%       0    [ELF Headers]
   0.2%     128   0.1%      64    .rodata.cst16
   0.2%     104   0.1%      40    .rodata.cst8
   0.2%      92   0.1%      28    .rodata.cst4
   0.1%      50   0.0%       0    [AR Symbol Table]
   0.0%      17   0.0%       0    [Unmapped]
 100.0%  57.3Ki 100.0%  44.7Ki    TOTAL
libtest_size_c_fxx.a
    FILE SIZE        VM SIZE
 --------------  --------------
  49.9%  35.3Ki  62.5%  35.2Ki    .text
  21.6%  15.3Ki  27.0%  15.2Ki    .rodata
   8.2%  5.80Ki  10.2%  5.73Ki    .rodata.str1.1
   6.4%  4.49Ki   0.0%       0    .symtab
   4.3%  3.06Ki   0.0%       0    .rela.rodata
   4.2%  2.95Ki   0.0%       0    .rela.text
   4.1%  2.90Ki   0.0%       0    .strtab
   0.3%     252   0.0%       0    [AR Headers]
   0.3%     208   0.2%     144    .rodata.cst16
   0.3%     192   0.0%       0    [ELF Headers]
   0.1%     104   0.1%      40    .rodata.cst8
   0.1%      92   0.0%      28    .rodata.cst4
   0.1%      66   0.0%       0    [AR Symbol Table]
   0.0%      17   0.0%       0    [Unmapped]
 100.0%  70.6Ki 100.0%  56.3Ki    TOTAL
libtest_size_c_fxx_std.a
    FILE SIZE        VM SIZE
 --------------  --------------
  61.7%  11.2Ki  90.6%  11.2Ki    .text
  11.7%  2.12Ki   0.0%       0    .rela.rodata
   7.0%  1.28Ki   0.0%       0    .rela.text
   5.8%  1.06Ki   0.0%       0    .symtab
   5.5%    1024   7.6%     960    .rodata
   3.1%     570   0.0%       0    .strtab
   1.4%     256   0.0%       0    [AR Headers]
   1.0%     192   1.0%     128    .rodata.cst16
   0.7%     138   0.0%       0    [AR Symbol Table]
   0.7%     128   0.5%      64    .rodata.cst8
   0.7%     128   0.0%       0    [ELF Headers]
   0.5%      96   0.3%      32    .rodata.cst4
   0.1%      15   0.0%       0    [Unmapped]
 100.0%  18.2Ki 100.0%  12.3Ki    TOTAL
```

## `zig build-lib -O ReleaseSmall --strip`

```
libtest_size_c_f128.a
    FILE SIZE        VM SIZE
 --------------  --------------
  36.8%  13.4Ki  53.4%  13.4Ki    .rodata
  16.4%  5.97Ki  23.6%  5.91Ki    .text
  15.9%  5.81Ki  22.9%  5.75Ki    .rodata.str1.1
  11.2%  4.09Ki   0.0%       0    .symtab
   8.6%  3.13Ki   0.0%       0    .rela.rodata
   7.4%  2.70Ki   0.0%       0    .strtab
   2.2%     808   0.0%       0    .rela.text
   0.7%     254   0.0%       0    [AR Headers]
   0.3%     128   0.0%       0    [ELF Headers]
   0.2%      80   0.1%      16    .rodata.cst16
   0.2%      76   0.0%      12    .rodata.cst4
   0.1%      20   0.0%       0    [AR Symbol Table]
   0.0%       6   0.0%       0    [Unmapped]
 100.0%  36.5Ki 100.0%  25.1Ki    TOTAL
libtest_size_c_f64.a
    FILE SIZE        VM SIZE
 --------------  --------------
  31.1%  15.0Ki  43.4%  15.0Ki    .text
  28.4%  13.7Ki  39.7%  13.7Ki    .rodata
  12.0%  5.81Ki  16.7%  5.75Ki    .rodata.str1.1
   9.7%  4.67Ki   0.0%       0    .symtab
   6.8%  3.28Ki   0.0%       0    .strtab
   6.5%  3.13Ki   0.0%       0    .rela.rodata
   4.1%  1.96Ki   0.0%       0    .rela.text
   0.5%     252   0.0%       0    [AR Headers]
   0.3%     128   0.0%       0    [ELF Headers]
   0.2%     112   0.1%      48    .rodata.cst16
   0.2%     104   0.1%      40    .rodata.cst8
   0.2%      92   0.1%      28    .rodata.cst4
   0.1%      50   0.0%       0    [AR Symbol Table]
   0.0%      11   0.0%       0    [Unmapped]
 100.0%  48.4Ki 100.0%  34.5Ki    TOTAL
libtest_size_c_fxx.a
    FILE SIZE        VM SIZE
 --------------  --------------
  35.5%  20.3Ki  48.9%  20.3Ki    .text
  26.8%  15.3Ki  36.8%  15.2Ki    .rodata
  10.2%  5.81Ki  13.9%  5.75Ki    .rodata.str1.1
   9.2%  5.23Ki   0.0%       0    .symtab
   6.7%  3.81Ki   0.0%       0    .strtab
   5.5%  3.13Ki   0.0%       0    .rela.rodata
   4.8%  2.73Ki   0.0%       0    .rela.text
   0.4%     252   0.0%       0    [AR Headers]
   0.3%     192   0.3%     128    .rodata.cst16
   0.2%     128   0.0%       0    [ELF Headers]
   0.2%     104   0.1%      40    .rodata.cst8
   0.2%      92   0.1%      28    .rodata.cst4
   0.1%      66   0.0%       0    [AR Symbol Table]
   0.0%      13   0.0%       0    [Unmapped]
 100.0%  57.2Ki 100.0%  41.4Ki    TOTAL
libtest_size_c_fxx_std.a
    FILE SIZE        VM SIZE
 --------------  --------------
  49.7%  8.05Ki  88.1%  7.99Ki    .text
  14.8%  2.41Ki   0.0%       0    .rela.text
  10.8%  1.75Ki   0.0%       0    .rela.rodata
   7.9%  1.28Ki   0.0%       0    .symtab
   5.6%     928   9.3%     864    .rodata
   4.5%     755   0.0%       0    .strtab
   1.5%     256   0.0%       0    [AR Headers]
   1.2%     192   1.4%     128    .rodata.cst16
   1.2%     192   0.0%       0    [ELF Headers]
   0.8%     138   0.0%       0    [AR Symbol Table]
   0.8%     128   0.7%      64    .rodata.cst8
   0.6%      96   0.3%      32    .rodata.cst4
   0.5%      82   0.2%      18    .rodata.str1.1
   0.1%      19   0.0%       0    [Unmapped]
 100.0%  16.2Ki 100.0%  9.07Ki    TOTAL
```
