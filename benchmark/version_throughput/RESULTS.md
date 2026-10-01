# Grape route throughput by version

Generated: 2026-10-01 08:55:15 CEST  
Ruby: ruby 4.0.7 (2026-09-15 revision 229531a6cf) +PRISM [arm64-darwin27]  
Host: Darwin 27.0.0 arm64  
JIT modes benched: No JIT, YJIT, ZJIT

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure. Each route shape has an independent table, so a static-route fast path cannot be mistaken for general request throughput. Released versions are benched once per Ruby and carried over; each run benches `master` again. Reproduce with `ruby benchmark/version_throughput/run.rb`.

## Static route

`GET /api/v1/hello` against one literal, path-versioned route.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 36,186 | 27.64 | — | — | 59,569 | 16.79 | — | — | +64.6% | 43,410 | 23.04 | — | — | +20.0% |
| 3.1.1 | 46,580 | 21.47 | +28.7% | +28.7% | 84,643 | 11.81 | +42.1% | +42.1% | +81.7% | 55,154 | 18.13 | +27.1% | +27.1% | +18.4% |
| 3.2.1 | 45,253 | 22.10 | -2.8% | +25.1% | 88,991 | 11.24 | +5.1% | +49.4% | +96.7% | 56,019 | 17.85 | +1.6% | +29.0% | +23.8% |
| 3.3.5 | 68,155 | 14.67 | +50.6% | +88.3% | 132,225 | 7.56 | +48.6% | +122.0% | +94.0% | 87,243 | 11.46 | +55.7% | +101.0% | +28.0% |
| 4.0.1 | 121,146 | 8.25 | +77.8% | +234.8% | 234,180 | 4.27 | +77.1% | +293.1% | +93.3% | 156,600 | 6.39 | +79.5% | +260.7% | +29.3% |
| master | 204,850 | 4.88 | +69.1% | +466.1% | 406,359 | 2.46 | +73.5% | +582.2% | +98.4% | 284,572 | 3.51 | +81.7% | +555.5% | +38.9% |

Over time, 3.0.1 → master: **+466.1%** without a JIT, **+582.2%** with YJIT, **+555.5%** with ZJIT.

## Parameterized route

`GET /api/v1/hello/42` against a path-versioned `get '/hello/:id'` route.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 35,786 | 27.94 | — | — | 56,532 | 17.69 | — | — | +58.0% | 41,141 | 24.31 | — | — | +15.0% |
| 3.1.1 | 42,888 | 23.32 | +19.8% | +19.8% | 78,136 | 12.80 | +38.2% | +38.2% | +82.2% | 54,048 | 18.50 | +31.4% | +31.4% | +26.0% |
| 3.2.1 | 44,707 | 22.37 | +4.2% | +24.9% | 83,360 | 12.00 | +6.7% | +47.5% | +86.5% | 54,568 | 18.33 | +1.0% | +32.6% | +22.1% |
| 3.3.5 | 64,721 | 15.45 | +44.8% | +80.9% | 126,601 | 7.90 | +51.9% | +123.9% | +95.6% | 82,106 | 12.18 | +50.5% | +99.6% | +26.9% |
| 4.0.1 | 112,253 | 8.91 | +73.4% | +213.7% | 210,106 | 4.76 | +66.0% | +271.7% | +87.2% | 144,902 | 6.90 | +76.5% | +252.2% | +29.1% |
| master | 162,897 | 6.14 | +45.1% | +355.2% | 308,763 | 3.24 | +47.0% | +446.2% | +89.5% | 222,187 | 4.50 | +53.3% | +440.1% | +36.4% |

Over time, 3.0.1 → master: **+355.2%** without a JIT, **+446.2%** with YJIT, **+440.1%** with ZJIT.

## Many static routes

`GET /api/v1/resource199`, the last of 200 literal, path-versioned routes.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 8,184 | 122.19 | — | — | 10,264 | 97.43 | — | — | +25.4% | 8,720 | 114.68 | — | — | +6.5% |
| 3.1.1 | 10,885 | 91.87 | +33.0% | +33.0% | 13,165 | 75.96 | +28.3% | +28.3% | +21.0% | 11,676 | 85.65 | +33.9% | +33.9% | +7.3% |
| 3.2.1 | 10,848 | 92.18 | -0.3% | +32.5% | 13,112 | 76.27 | -0.4% | +27.7% | +20.9% | 11,653 | 85.81 | -0.2% | +33.6% | +7.4% |
| 3.3.5 | 11,891 | 84.10 | +9.6% | +45.3% | 13,728 | 72.85 | +4.7% | +33.7% | +15.4% | 12,547 | 79.70 | +7.7% | +43.9% | +5.5% |
| 4.0.1 | 15,183 | 65.86 | +27.7% | +85.5% | 17,123 | 58.40 | +24.7% | +66.8% | +12.8% | 16,267 | 61.47 | +29.7% | +86.5% | +7.1% |
| master | 203,452 | 4.92 | +1240.0% | +2385.9% | 410,854 | 2.43 | +2299.4% | +3903.0% | +101.9% | 281,410 | 3.55 | +1629.9% | +3127.1% | +38.3% |

Over time, 3.0.1 → master: **+2385.9%** without a JIT, **+3903.0%** with YJIT, **+3127.1%** with ZJIT.

## Many parameterized routes

`GET /api/v1/resource199/42`, the last of 200 path-versioned `get '/resourceN/:id'` routes.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 7,438 | 134.44 | — | — | 8,980 | 111.36 | — | — | +20.7% | 7,825 | 127.79 | — | — | +5.2% |
| 3.1.1 | 9,673 | 103.38 | +30.0% | +30.0% | 11,094 | 90.14 | +23.5% | +23.5% | +14.7% | 10,248 | 97.58 | +31.0% | +31.0% | +5.9% |
| 3.2.1 | 9,568 | 104.52 | -1.1% | +28.6% | 11,289 | 88.58 | +1.8% | +25.7% | +18.0% | 10,328 | 96.82 | +0.8% | +32.0% | +7.9% |
| 3.3.5 | 10,420 | 95.97 | +8.9% | +40.1% | 11,783 | 84.87 | +4.4% | +31.2% | +13.1% | 10,837 | 92.28 | +4.9% | +38.5% | +4.0% |
| 4.0.1 | 12,889 | 77.59 | +23.7% | +73.3% | 14,236 | 70.25 | +20.8% | +58.5% | +10.5% | 13,618 | 73.43 | +25.7% | +74.0% | +5.7% |
| master | 143,645 | 6.96 | +1014.5% | +1831.1% | 268,475 | 3.72 | +1786.0% | +2889.7% | +86.9% | 192,800 | 5.19 | +1315.8% | +2363.8% | +34.2% |

Over time, 3.0.1 → master: **+1831.1%** without a JIT, **+2889.7%** with YJIT, **+2363.8%** with ZJIT.

## Notes
- All versions exercise the same route-shape APIs, kept stable in `app.rb`.
- `vs prev` compares throughput against the previous benched version and `vs <first>` against the oldest one in the same table; read those columns for improvement over time.
- Compare a route shape across versions, not i/s across route shapes: a change that speeds up one shape, such as a lookup for literal paths, need not move the others.
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `<JIT> speedup` is that JIT's throughput against the No JIT pass on the same row.
- JIT passes use `ruby --yjit` and `ruby --zjit`; every pass shares the same Ruby binary. Only one JIT can be enabled at a time, so each gets its own pass.
