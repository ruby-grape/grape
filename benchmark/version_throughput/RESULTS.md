# Grape route throughput by version

Generated: 2026-10-31 11:39:27 CET  
Ruby: ruby 4.0.9 (2026-10-23 revision 3e93b23afc) +PRISM [arm64-darwin27]  
Host: Darwin 27.0.0 arm64  
JIT modes benched: No JIT, YJIT, ZJIT

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure. Each route shape has an independent table, so a static-route fast path cannot be mistaken for general request throughput. Released versions are benched once per Ruby and carried over; each run benches `master` again. Reproduce with `ruby benchmark/version_throughput/run.rb`.

## Static route

`GET /api/v1/hello` against one literal, path-versioned route.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 35,178 | 28.43 | — | — | 57,852 | 17.29 | — | — | +64.5% | 40,648 | 24.60 | — | — | +15.6% |
| 3.1.1 | 46,807 | 21.36 | +33.1% | +33.1% | 86,931 | 11.50 | +50.3% | +50.3% | +85.7% | 59,159 | 16.90 | +45.5% | +45.5% | +26.4% |
| 3.2.1 | 47,972 | 20.85 | +2.5% | +36.4% | 88,743 | 11.27 | +2.1% | +53.4% | +85.0% | 58,021 | 17.24 | -1.9% | +42.7% | +20.9% |
| 3.3.5 | 70,028 | 14.28 | +46.0% | +99.1% | 137,873 | 7.25 | +55.4% | +138.3% | +96.9% | 87,875 | 11.38 | +51.5% | +116.2% | +25.5% |
| 4.0.1 | 121,241 | 8.25 | +73.1% | +244.7% | 220,360 | 4.54 | +59.8% | +280.9% | +81.8% | 158,654 | 6.30 | +80.5% | +290.3% | +30.9% |
| 4.1.0 | 205,538 | 4.87 | +69.5% | +484.3% | 407,972 | 2.45 | +85.1% | +605.2% | +98.5% | 312,859 | 3.20 | +97.2% | +669.7% | +52.2% |
| master | 209,097 | 4.78 | +1.7% | +494.4% | 433,585 | 2.31 | +6.3% | +649.5% | +107.4% | 311,395 | 3.21 | -0.5% | +666.1% | +48.9% |

Over time, 3.0.1 → master: **+494.4%** without a JIT, **+649.5%** with YJIT, **+666.1%** with ZJIT.

## Parameterized route

`GET /api/v1/hello/42` against a path-versioned `get '/hello/:id'` route.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 33,983 | 29.43 | — | — | 51,734 | 19.33 | — | — | +52.2% | 41,486 | 24.10 | — | — | +22.1% |
| 3.1.1 | 43,227 | 23.13 | +27.2% | +27.2% | 81,920 | 12.21 | +58.3% | +58.3% | +89.5% | 56,430 | 17.72 | +36.0% | +36.0% | +30.5% |
| 3.2.1 | 45,683 | 21.89 | +5.7% | +34.4% | 88,134 | 11.35 | +7.6% | +70.4% | +92.9% | 54,734 | 18.27 | -3.0% | +31.9% | +19.8% |
| 3.3.5 | 66,450 | 15.05 | +45.5% | +95.5% | 119,258 | 8.39 | +35.3% | +130.5% | +79.5% | 80,955 | 12.35 | +47.9% | +95.1% | +21.8% |
| 4.0.1 | 111,958 | 8.93 | +68.5% | +229.5% | 209,107 | 4.78 | +75.3% | +304.2% | +86.8% | 141,611 | 7.06 | +74.9% | +241.3% | +26.5% |
| 4.1.0 | 161,109 | 6.21 | +43.9% | +374.1% | 315,384 | 3.17 | +50.8% | +509.6% | +95.8% | 236,529 | 4.23 | +67.0% | +470.1% | +46.8% |
| master | 152,794 | 6.54 | -5.2% | +349.6% | 293,868 | 3.40 | -6.8% | +468.0% | +92.3% | 234,109 | 4.27 | -1.0% | +464.3% | +53.2% |

Over time, 3.0.1 → master: **+349.6%** without a JIT, **+468.0%** with YJIT, **+464.3%** with ZJIT.

## Many static routes

`GET /api/v1/resource199`, the last of 200 literal, path-versioned routes.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 8,007 | 124.89 | — | — | 10,388 | 96.27 | — | — | +29.7% | 8,699 | 114.95 | — | — | +8.6% |
| 3.1.1 | 11,382 | 87.86 | +42.2% | +42.2% | 13,783 | 72.55 | +32.7% | +32.7% | +21.1% | 12,279 | 81.44 | +41.2% | +41.2% | +7.9% |
| 3.2.1 | 11,375 | 87.91 | -0.1% | +42.1% | 13,553 | 73.79 | -1.7% | +30.5% | +19.1% | 11,992 | 83.39 | -2.3% | +37.9% | +5.4% |
| 3.3.5 | 12,312 | 81.22 | +8.2% | +53.8% | 14,104 | 70.90 | +4.1% | +35.8% | +14.6% | 12,974 | 77.08 | +8.2% | +49.1% | +5.4% |
| 4.0.1 | 15,684 | 63.76 | +27.4% | +95.9% | 17,660 | 56.63 | +25.2% | +70.0% | +12.6% | 16,676 | 59.97 | +28.5% | +91.7% | +6.3% |
| 4.1.0 | 203,861 | 4.91 | +1199.8% | +2446.1% | 426,242 | 2.35 | +2313.6% | +4003.4% | +109.1% | 303,086 | 3.30 | +1717.5% | +3384.1% | +48.7% |
| master | 207,055 | 4.83 | +1.6% | +2485.9% | 433,345 | 2.31 | +1.7% | +4071.7% | +109.3% | 310,166 | 3.22 | +2.3% | +3465.5% | +49.8% |

Over time, 3.0.1 → master: **+2485.9%** without a JIT, **+4071.7%** with YJIT, **+3465.5%** with ZJIT.

## Many parameterized routes

`GET /api/v1/resource199/42`, the last of 200 path-versioned `get '/resourceN/:id'` routes.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 7,400 | 135.13 | — | — | 9,072 | 110.23 | — | — | +22.6% | 7,755 | 128.95 | — | — | +4.8% |
| 3.1.1 | 9,871 | 101.31 | +33.4% | +33.4% | 11,658 | 85.78 | +28.5% | +28.5% | +18.1% | 10,509 | 95.16 | +35.5% | +35.5% | +6.5% |
| 3.2.1 | 9,833 | 101.70 | -0.4% | +32.9% | 11,645 | 85.87 | -0.1% | +28.4% | +18.4% | 10,516 | 95.09 | +0.1% | +35.6% | +6.9% |
| 3.3.5 | 10,551 | 94.78 | +7.3% | +42.6% | 12,097 | 82.66 | +3.9% | +33.3% | +14.7% | 11,033 | 90.64 | +4.9% | +42.3% | +4.6% |
| 4.0.1 | 12,986 | 77.01 | +23.1% | +75.5% | 14,706 | 68.00 | +21.6% | +62.1% | +13.2% | 13,913 | 71.87 | +26.1% | +79.4% | +7.1% |
| 4.1.0 | 144,552 | 6.92 | +1013.1% | +1853.3% | 273,336 | 3.66 | +1758.6% | +2912.9% | +89.1% | 201,405 | 4.97 | +1347.6% | +2497.0% | +39.3% |
| master | 140,016 | 7.14 | -3.1% | +1792.0% | 276,760 | 3.61 | +1.3% | +2950.6% | +97.7% | 209,947 | 4.76 | +4.2% | +2607.2% | +49.9% |

Over time, 3.0.1 → master: **+1792.0%** without a JIT, **+2950.6%** with YJIT, **+2607.2%** with ZJIT.

## Notes
- All versions exercise the same route-shape APIs, kept stable in `app.rb`.
- `vs prev` compares throughput against the previous benched version and `vs <first>` against the oldest one in the same table; read those columns for improvement over time.
- Compare a route shape across versions, not i/s across route shapes: a change that speeds up one shape, such as a lookup for literal paths, need not move the others.
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `<JIT> speedup` is that JIT's throughput against the No JIT pass on the same row.
- JIT passes use `ruby --yjit` and `ruby --zjit`; every pass shares the same Ruby binary. Only one JIT can be enabled at a time, so each gets its own pass.
