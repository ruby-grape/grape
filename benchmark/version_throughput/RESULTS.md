# Grape throughput by version

Generated: 2026-09-04 21:50:19 CEST  
Ruby: ruby 4.0.5 (2026-05-20 revision 64336ffd0e) +PRISM [arm64-darwin25]  
Host: Darwin 25.6.0 arm64  
YJIT available: true

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure, `BenchAPI.call(env)` against `/api/v1/hello` returning a small JSON object. Reproduce with `ruby benchmark/version_throughput/run.rb`.

| Version | No-YJIT (i/s) | μs/req | vs prev | vs 3.0.0 | YJIT (i/s) | μs/req | vs prev | vs 3.0.0 | YJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.0 | 34,135 | 29.30 | — | — | 55,271 | 18.09 | — | — | +61.9% |
| 3.1.0 | 44,942 | 22.25 | +31.7% | +31.7% | 83,835 | 11.93 | +51.7% | +51.7% | +86.5% |
| 3.2.0 | 46,015 | 21.73 | +2.4% | +34.8% | 86,605 | 11.55 | +3.3% | +56.7% | +88.2% |
| 3.3.0 | 64,924 | 15.40 | +41.1% | +90.2% | 133,003 | 7.52 | +53.6% | +140.6% | +104.9% |
| 3.3.5 | 64,404 | 15.53 | -0.8% | +88.7% | 134,421 | 7.44 | +1.1% | +143.2% | +108.7% |
| master | 118,769 | 8.42 | +84.4% | +247.9% | 229,512 | 4.36 | +70.7% | +315.2% | +93.2% |

Over time, 3.0.0 → master: **+247.9%** without YJIT, **+315.2%** with YJIT.

## Notes
- All versions exercised through the same `BenchAPI` definition (kept stable in `app.rb`).
- `vs prev` compares throughput against the previous benched version and `vs 3.0.0` against the first one; read those columns for improvement over time.
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `YJIT speedup` is `(yjit_ips - no_yjit_ips) / no_yjit_ips`.
- YJIT pass uses `ruby --yjit`; both passes share the same Ruby binary.
