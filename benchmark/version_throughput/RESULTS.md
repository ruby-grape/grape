# Grape route throughput by version

Generated: 2026-09-13 10:56:02 CEST  
Ruby: ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin25]  
Host: Darwin 25.6.0 arm64  
JIT modes benched: No JIT, YJIT, ZJIT

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure. Each route shape has an independent table, so a static-route fast path cannot be mistaken for general request throughput. Reproduce with `ruby benchmark/version_throughput/run.rb`.

## Static route

`GET /api/v1/hello` against one literal, path-versioned route.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 35,764 | 27.96 | — | — | 55,772 | 17.93 | — | — | +55.9% | 41,392 | 24.16 | — | — | +15.7% |
| 3.1.1 | 44,662 | 22.39 | +24.9% | +24.9% | 84,759 | 11.80 | +52.0% | +52.0% | +89.8% | 56,453 | 17.71 | +36.4% | +36.4% | +26.4% |
| 3.2.1 | 46,297 | 21.60 | +3.7% | +29.5% | 87,562 | 11.42 | +3.3% | +57.0% | +89.1% | 57,302 | 17.45 | +1.5% | +38.4% | +23.8% |
| 3.3.5 | 67,592 | 14.79 | +46.0% | +89.0% | 137,148 | 7.29 | +56.6% | +145.9% | +102.9% | 86,717 | 11.53 | +51.3% | +109.5% | +28.3% |
| 4.0.0 | 122,754 | 8.15 | +81.6% | +243.2% | 226,561 | 4.41 | +65.2% | +306.2% | +84.6% | 149,777 | 6.68 | +72.7% | +261.8% | +22.0% |
| master | 155,284 | 6.44 | +26.5% | +334.2% | 324,582 | 3.08 | +43.3% | +482.0% | +109.0% | 206,670 | 4.84 | +38.0% | +399.3% | +33.1% |

Over time, 3.0.1 → master: **+334.2%** without a JIT, **+482.0%** with YJIT, **+399.3%** with ZJIT.

## Parameterized route

`GET /api/v1/hello/42` against a path-versioned `get '/hello/:id'` route.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 33,850 | 29.54 | — | — | 52,474 | 19.06 | — | — | +55.0% | 40,313 | 24.81 | — | — | +19.1% |
| 3.1.1 | 42,575 | 23.49 | +25.8% | +25.8% | 80,357 | 12.44 | +53.1% | +53.1% | +88.7% | 53,866 | 18.56 | +33.6% | +33.6% | +26.5% |
| 3.2.1 | 45,198 | 22.12 | +6.2% | +33.5% | 86,041 | 11.62 | +7.1% | +64.0% | +90.4% | 53,474 | 18.70 | -0.7% | +32.6% | +18.3% |
| 3.3.5 | 62,620 | 15.97 | +38.5% | +85.0% | 126,198 | 7.92 | +46.7% | +140.5% | +101.5% | 79,484 | 12.58 | +48.6% | +97.2% | +26.9% |
| 4.0.0 | 113,603 | 8.80 | +81.4% | +235.6% | 206,338 | 4.85 | +63.5% | +293.2% | +81.6% | 139,759 | 7.16 | +75.8% | +246.7% | +23.0% |
| master | 128,593 | 7.78 | +13.2% | +279.9% | 242,847 | 4.12 | +17.7% | +362.8% | +88.8% | 168,756 | 5.93 | +20.7% | +318.6% | +31.2% |

Over time, 3.0.1 → master: **+279.9%** without a JIT, **+362.8%** with YJIT, **+318.6%** with ZJIT.

## Many static routes

`GET /api/v1/resource199`, the last of 200 literal, path-versioned routes.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 8,535 | 117.17 | — | — | 10,691 | 93.54 | — | — | +25.3% | 9,020 | 110.86 | — | — | +5.7% |
| 3.1.1 | 12,235 | 81.73 | +43.4% | +43.4% | 14,772 | 67.69 | +38.2% | +38.2% | +20.7% | 13,044 | 76.66 | +44.6% | +44.6% | +6.6% |
| 3.2.1 | 12,306 | 81.26 | +0.6% | +44.2% | 14,605 | 68.47 | -1.1% | +36.6% | +18.7% | 13,054 | 76.60 | +0.1% | +44.7% | +6.1% |
| 3.3.5 | 13,229 | 75.59 | +7.5% | +55.0% | 15,428 | 64.82 | +5.6% | +44.3% | +16.6% | 14,009 | 71.38 | +7.3% | +55.3% | +5.9% |
| 4.0.0 | 17,328 | 57.71 | +31.0% | +103.0% | 19,681 | 50.81 | +27.6% | +84.1% | +13.6% | 18,688 | 53.51 | +33.4% | +107.2% | +7.8% |
| master | 154,249 | 6.48 | +790.2% | +1707.3% | 306,408 | 3.26 | +1456.9% | +2766.1% | +98.6% | 197,890 | 5.05 | +958.9% | +2093.9% | +28.3% |

Over time, 3.0.1 → master: **+1707.3%** without a JIT, **+2766.1%** with YJIT, **+2093.9%** with ZJIT.

## Many parameterized routes

`GET /api/v1/resource199/42`, the last of 200 path-versioned `get '/resourceN/:id'` routes.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 7,676 | 130.28 | — | — | 9,630 | 103.84 | — | — | +25.5% | 8,310 | 120.34 | — | — | +8.3% |
| 3.1.1 | 10,749 | 93.03 | +40.0% | +40.0% | 12,670 | 78.93 | +31.6% | +31.6% | +17.9% | 11,185 | 89.40 | +34.6% | +34.6% | +4.1% |
| 3.2.1 | 10,782 | 92.75 | +0.3% | +40.5% | 12,726 | 78.58 | +0.4% | +32.1% | +18.0% | 11,441 | 87.40 | +2.3% | +37.7% | +6.1% |
| 3.3.5 | 11,531 | 86.72 | +6.9% | +50.2% | 13,337 | 74.98 | +4.8% | +38.5% | +15.7% | 11,931 | 83.82 | +4.3% | +43.6% | +3.5% |
| 4.0.0 | 14,566 | 68.65 | +26.3% | +89.8% | 16,256 | 61.52 | +21.9% | +68.8% | +11.6% | 15,381 | 65.02 | +28.9% | +85.1% | +5.6% |
| master | 14,776 | 67.68 | +1.4% | +92.5% | 16,554 | 60.41 | +1.8% | +71.9% | +12.0% | 15,626 | 64.00 | +1.6% | +88.0% | +5.8% |

Over time, 3.0.1 → master: **+92.5%** without a JIT, **+71.9%** with YJIT, **+88.0%** with ZJIT.

## Notes
- All versions exercise the same route-shape APIs, kept stable in `app.rb`.
- `vs prev` compares throughput against the previous benched version and `vs <first>` against the oldest one in the same table; read those columns for improvement over time.
- Compare a route shape across versions, not i/s across route shapes: a change that speeds up one shape, such as a lookup for literal paths, need not move the others.
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `<JIT> speedup` is that JIT's throughput against the No JIT pass on the same row.
- JIT passes use `ruby --yjit` and `ruby --zjit`; every pass shares the same Ruby binary. Only one JIT can be enabled at a time, so each gets its own pass.
