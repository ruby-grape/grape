# Grape throughput by version

Generated: 2026-09-15 23:37:39 CEST  
Ruby: ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin25]  
Host: Darwin 25.6.0 arm64  
YJIT available: true

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure, `BenchAPI.call(env)` against `/api/v1/hello` returning a small JSON object. Reproduce with `ruby benchmark/version_throughput/run.rb`.

| Version | No-YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 35,162 | 28.44 | — | — | 56,904 | 17.57 | — | — | +61.8% |
| 3.1.1 | 45,144 | 22.15 | +28.4% | +28.4% | 82,260 | 12.16 | +44.6% | +44.6% | +82.2% |
| 3.2.1 | 45,815 | 21.83 | +1.5% | +30.3% | 83,072 | 12.04 | +1.0% | +46.0% | +81.3% |
| 3.3.5 | 66,293 | 15.08 | +44.7% | +88.5% | 133,469 | 7.49 | +60.7% | +134.6% | +101.3% |
| 4.0.0 | 115,860 | 8.63 | +74.8% | +229.5% | 235,453 | 4.25 | +76.4% | +313.8% | +103.2% |
| master | 122,295 | 8.18 | +5.6% | +247.8% | 225,982 | 4.43 | -4.0% | +297.1% | +84.8% |

Over time, 3.0.1 → master: **+247.8%** without YJIT, **+297.1%** with YJIT.

## Notes
- All versions exercised through the same `BenchAPI` definition (kept stable in `app.rb`).
- `vs prev` compares throughput against the previous benched version and `vs 3.0.1` against the first one; read those columns for improvement over time.
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `YJIT speedup` is `(yjit_ips - no_yjit_ips) / no_yjit_ips`.
- YJIT pass uses `ruby --yjit`; both passes share the same Ruby binary.
