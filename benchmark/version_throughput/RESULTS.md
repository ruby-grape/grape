# Grape route throughput by version

Generated: 2026-09-13 19:27:30 CEST  
Ruby: ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin25]  
Host: Darwin 25.6.0 arm64  
JIT modes benched: No JIT, YJIT, ZJIT

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure. Each route shape has an independent table, so a static-route fast path cannot be mistaken for general request throughput. Reproduce with `ruby benchmark/version_throughput/run.rb`.

## Static route

`GET /api/v1/hello` against one literal, path-versioned route.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 34,383 | 29.08 | — | — | 56,257 | 17.78 | — | — | +63.6% | 41,398 | 24.16 | — | — | +20.4% |
| 3.1.1 | 43,533 | 22.97 | +26.6% | +26.6% | 84,684 | 11.81 | +50.5% | +50.5% | +94.5% | 53,632 | 18.65 | +29.6% | +29.6% | +23.2% |
| 3.2.1 | 44,507 | 22.47 | +2.2% | +29.4% | 85,762 | 11.66 | +1.3% | +52.4% | +92.7% | 54,489 | 18.35 | +1.6% | +31.6% | +22.4% |
| 3.3.5 | 63,684 | 15.70 | +43.1% | +85.2% | 134,370 | 7.44 | +56.7% | +138.8% | +111.0% | 85,579 | 11.69 | +57.1% | +106.7% | +34.4% |
| 4.0.0 | 118,375 | 8.45 | +85.9% | +244.3% | 225,178 | 4.44 | +67.6% | +300.3% | +90.2% | 146,964 | 6.80 | +71.7% | +255.0% | +24.2% |
| master | 157,683 | 6.34 | +33.2% | +358.6% | 313,952 | 3.19 | +39.4% | +458.1% | +99.1% | 208,519 | 4.80 | +41.9% | +403.7% | +32.2% |

Over time, 3.0.1 → master: **+358.6%** without a JIT, **+458.1%** with YJIT, **+403.7%** with ZJIT.

## Parameterized route

`GET /api/v1/hello/42` against a path-versioned `get '/hello/:id'` route.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 33,318 | 30.01 | — | — | 52,802 | 18.94 | — | — | +58.5% | 39,428 | 25.36 | — | — | +18.3% |
| 3.1.1 | 41,793 | 23.93 | +25.4% | +25.4% | 79,385 | 12.60 | +50.3% | +50.3% | +89.9% | 54,451 | 18.37 | +38.1% | +38.1% | +30.3% |
| 3.2.1 | 43,069 | 23.22 | +3.1% | +29.3% | 81,429 | 12.28 | +2.6% | +54.2% | +89.1% | 51,927 | 19.26 | -4.6% | +31.7% | +20.6% |
| 3.3.5 | 60,972 | 16.40 | +41.6% | +83.0% | 124,143 | 8.06 | +52.5% | +135.1% | +103.6% | 79,978 | 12.50 | +54.0% | +102.8% | +31.2% |
| 4.0.0 | 108,826 | 9.19 | +78.5% | +226.6% | 213,895 | 4.68 | +72.3% | +305.1% | +96.5% | 141,123 | 7.09 | +76.5% | +257.9% | +29.7% |
| master | 130,330 | 7.67 | +19.8% | +291.2% | 249,438 | 4.01 | +16.6% | +372.4% | +91.4% | 161,566 | 6.19 | +14.5% | +309.8% | +24.0% |

Over time, 3.0.1 → master: **+291.2%** without a JIT, **+372.4%** with YJIT, **+309.8%** with ZJIT.

## Many static routes

`GET /api/v1/resource199`, the last of 200 literal, path-versioned routes.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 8,373 | 119.44 | — | — | 10,653 | 93.87 | — | — | +27.2% | 8,826 | 113.31 | — | — | +5.4% |
| 3.1.1 | 11,855 | 84.35 | +41.6% | +41.6% | 14,302 | 69.92 | +34.3% | +34.3% | +20.6% | 12,784 | 78.22 | +44.9% | +44.9% | +7.8% |
| 3.2.1 | 11,833 | 84.51 | -0.2% | +41.3% | 14,353 | 69.67 | +0.4% | +34.7% | +21.3% | 12,556 | 79.65 | -1.8% | +42.3% | +6.1% |
| 3.3.5 | 12,820 | 78.00 | +8.3% | +53.1% | 14,996 | 66.69 | +4.5% | +40.8% | +17.0% | 13,603 | 73.52 | +8.3% | +54.1% | +6.1% |
| 4.0.0 | 17,377 | 57.55 | +35.5% | +107.5% | 19,777 | 50.56 | +31.9% | +85.6% | +13.8% | 18,787 | 53.23 | +38.1% | +112.9% | +8.1% |
| master | 154,126 | 6.49 | +787.0% | +1740.8% | 307,715 | 3.25 | +1455.9% | +2788.5% | +99.7% | 201,657 | 4.96 | +973.4% | +2184.9% | +30.8% |

Over time, 3.0.1 → master: **+1740.8%** without a JIT, **+2788.5%** with YJIT, **+2184.9%** with ZJIT.

## Many parameterized routes

`GET /api/v1/resource199/42`, the last of 200 path-versioned `get '/resourceN/:id'` routes.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 7,561 | 132.26 | — | — | 9,565 | 104.55 | — | — | +26.5% | 8,080 | 123.76 | — | — | +6.9% |
| 3.1.1 | 10,412 | 96.04 | +37.7% | +37.7% | 12,333 | 81.09 | +28.9% | +28.9% | +18.4% | 11,122 | 89.91 | +37.6% | +37.6% | +6.8% |
| 3.2.1 | 10,382 | 96.32 | -0.3% | +37.3% | 12,305 | 81.26 | -0.2% | +28.6% | +18.5% | 11,091 | 90.16 | -0.3% | +37.3% | +6.8% |
| 3.3.5 | 11,364 | 88.00 | +9.5% | +50.3% | 12,868 | 77.71 | +4.6% | +34.5% | +13.2% | 11,750 | 85.11 | +5.9% | +45.4% | +3.4% |
| 4.0.0 | 14,535 | 68.80 | +27.9% | +92.2% | 16,321 | 61.27 | +26.8% | +70.6% | +12.3% | 15,377 | 65.03 | +30.9% | +90.3% | +5.8% |
| master | 14,456 | 69.18 | -0.5% | +91.2% | 16,189 | 61.77 | -0.8% | +69.3% | +12.0% | 15,352 | 65.14 | -0.2% | +90.0% | +6.2% |

Over time, 3.0.1 → master: **+91.2%** without a JIT, **+69.3%** with YJIT, **+90.0%** with ZJIT.

## Notes
- All versions exercise the same route-shape APIs, kept stable in `app.rb`.
- `vs prev` compares throughput against the previous benched version and `vs <first>` against the oldest one in the same table; read those columns for improvement over time.
- Compare a route shape across versions, not i/s across route shapes: a change that speeds up one shape, such as a lookup for literal paths, need not move the others.
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `<JIT> speedup` is that JIT's throughput against the No JIT pass on the same row.
- JIT passes use `ruby --yjit` and `ruby --zjit`; every pass shares the same Ruby binary. Only one JIT can be enabled at a time, so each gets its own pass.
