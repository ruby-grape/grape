# Grape route throughput by version

Generated: 2026-09-18 10:07:50 CEST  
Ruby: ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin25]  
Host: Darwin 27.0.0 arm64  
JIT modes benched: No JIT, YJIT, ZJIT

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure. Each route shape has an independent table, so a static-route fast path cannot be mistaken for general request throughput. Released versions are benched once per Ruby and carried over; each run benches `master` again. Reproduce with `ruby benchmark/version_throughput/run.rb`.

## Static route

`GET /api/v1/hello` against one literal, path-versioned route.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 33,175 | 30.14 | — | — | 55,370 | 18.06 | — | — | +66.9% | 41,927 | 23.85 | — | — | +26.4% |
| 3.1.1 | 45,369 | 22.04 | +36.8% | +36.8% | 84,068 | 11.90 | +51.8% | +51.8% | +85.3% | 55,237 | 18.10 | +31.7% | +31.7% | +21.8% |
| 3.2.1 | 46,594 | 21.46 | +2.7% | +40.4% | 88,161 | 11.34 | +4.9% | +59.2% | +89.2% | 56,755 | 17.62 | +2.7% | +35.4% | +21.8% |
| 3.3.5 | 67,489 | 14.82 | +44.8% | +103.4% | 138,268 | 7.23 | +56.8% | +149.7% | +104.9% | 87,007 | 11.49 | +53.3% | +107.5% | +28.9% |
| 4.0.1 | 119,363 | 8.38 | +76.9% | +259.8% | 234,084 | 4.27 | +69.3% | +322.8% | +96.1% | 151,349 | 6.61 | +74.0% | +261.0% | +26.8% |
| master | 176,991 | 5.65 | +48.3% | +433.5% | 365,469 | 2.74 | +56.1% | +560.0% | +106.5% | 233,729 | 4.28 | +54.4% | +457.5% | +32.1% |

Over time, 3.0.1 → master: **+433.5%** without a JIT, **+560.0%** with YJIT, **+457.5%** with ZJIT.

## Parameterized route

`GET /api/v1/hello/42` against a path-versioned `get '/hello/:id'` route.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 34,022 | 29.39 | — | — | 53,966 | 18.53 | — | — | +58.6% | 41,163 | 24.29 | — | — | +21.0% |
| 3.1.1 | 42,336 | 23.62 | +24.4% | +24.4% | 81,484 | 12.27 | +51.0% | +51.0% | +92.5% | 55,170 | 18.13 | +34.0% | +34.0% | +30.3% |
| 3.2.1 | 44,905 | 22.27 | +6.1% | +32.0% | 85,515 | 11.69 | +4.9% | +58.5% | +90.4% | 56,074 | 17.83 | +1.6% | +36.2% | +24.9% |
| 3.3.5 | 64,020 | 15.62 | +42.6% | +88.2% | 125,728 | 7.95 | +47.0% | +133.0% | +96.4% | 82,136 | 12.17 | +46.5% | +99.5% | +28.3% |
| 4.0.1 | 110,980 | 9.01 | +73.4% | +226.2% | 213,641 | 4.68 | +69.9% | +295.9% | +92.5% | 141,087 | 7.09 | +71.8% | +242.8% | +27.1% |
| master | 146,964 | 6.80 | +32.4% | +332.0% | 293,410 | 3.41 | +37.3% | +443.7% | +99.6% | 198,794 | 5.03 | +40.9% | +382.9% | +35.3% |

Over time, 3.0.1 → master: **+332.0%** without a JIT, **+443.7%** with YJIT, **+382.9%** with ZJIT.

## Many static routes

`GET /api/v1/resource199`, the last of 200 literal, path-versioned routes.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 8,488 | 117.82 | — | — | 10,877 | 91.94 | — | — | +28.1% | 8,821 | 113.37 | — | — | +3.9% |
| 3.1.1 | 12,201 | 81.96 | +43.7% | +43.7% | 14,771 | 67.70 | +35.8% | +35.8% | +21.1% | 13,129 | 76.17 | +48.8% | +48.8% | +7.6% |
| 3.2.1 | 12,338 | 81.05 | +1.1% | +45.4% | 14,871 | 67.25 | +0.7% | +36.7% | +20.5% | 13,120 | 76.22 | -0.1% | +48.7% | +6.3% |
| 3.3.5 | 13,192 | 75.80 | +6.9% | +55.4% | 15,261 | 65.53 | +2.6% | +40.3% | +15.7% | 13,975 | 71.56 | +6.5% | +58.4% | +5.9% |
| 4.0.1 | 17,308 | 57.78 | +31.2% | +103.9% | 19,912 | 50.22 | +30.5% | +83.1% | +15.0% | 18,496 | 54.07 | +32.4% | +109.7% | +6.9% |
| master | 185,997 | 5.38 | +974.6% | +2091.3% | 375,777 | 2.66 | +1787.2% | +3354.8% | +102.0% | 245,930 | 4.07 | +1229.6% | +2688.0% | +32.2% |

Over time, 3.0.1 → master: **+2091.3%** without a JIT, **+3354.8%** with YJIT, **+2688.0%** with ZJIT.

## Many parameterized routes

`GET /api/v1/resource199/42`, the last of 200 path-versioned `get '/resourceN/:id'` routes.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 7,596 | 131.65 | — | — | 9,838 | 101.65 | — | — | +29.5% | 8,274 | 120.85 | — | — | +8.9% |
| 3.1.1 | 10,610 | 94.25 | +39.7% | +39.7% | 12,669 | 78.93 | +28.8% | +28.8% | +19.4% | 11,453 | 87.31 | +38.4% | +38.4% | +7.9% |
| 3.2.1 | 10,810 | 92.51 | +1.9% | +42.3% | 12,760 | 78.37 | +0.7% | +29.7% | +18.0% | 11,394 | 87.76 | -0.5% | +37.7% | +5.4% |
| 3.3.5 | 11,523 | 86.79 | +6.6% | +51.7% | 13,170 | 75.93 | +3.2% | +33.9% | +14.3% | 12,106 | 82.60 | +6.2% | +46.3% | +5.1% |
| 4.0.1 | 14,497 | 68.98 | +25.8% | +90.9% | 16,322 | 61.27 | +23.9% | +65.9% | +12.6% | 15,433 | 64.80 | +27.5% | +86.5% | +6.5% |
| master | 133,473 | 7.49 | +820.7% | +1657.1% | 249,500 | 4.01 | +1428.6% | +2436.1% | +86.9% | 176,631 | 5.66 | +1044.5% | +2034.8% | +32.3% |

Over time, 3.0.1 → master: **+1657.1%** without a JIT, **+2436.1%** with YJIT, **+2034.8%** with ZJIT.

## Notes
- All versions exercise the same route-shape APIs, kept stable in `app.rb`.
- `vs prev` compares throughput against the previous benched version and `vs <first>` against the oldest one in the same table; read those columns for improvement over time.
- Compare a route shape across versions, not i/s across route shapes: a change that speeds up one shape, such as a lookup for literal paths, need not move the others.
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `<JIT> speedup` is that JIT's throughput against the No JIT pass on the same row.
- JIT passes use `ruby --yjit` and `ruby --zjit`; every pass shares the same Ruby binary. Only one JIT can be enabled at a time, so each gets its own pass.
