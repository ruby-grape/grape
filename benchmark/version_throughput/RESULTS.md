# Grape throughput by version

Generated: 2026-09-07 18:53:55 CEST  
Ruby: ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin25]  
Host: Darwin 25.6.0 arm64  
JIT modes benched: No JIT, YJIT, ZJIT

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure, `BenchAPI.call(env)` against `/api/v1/hello` returning a small JSON object. Reproduce with `ruby benchmark/version_throughput/run.rb`.

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 34,645 | 28.86 | — | — | 54,054 | 18.50 | — | — | +56.0% | 40,893 | 24.45 | — | — | +18.0% |
| 3.1.1 | 44,818 | 22.31 | +29.4% | +29.4% | 84,212 | 11.87 | +55.8% | +55.8% | +87.9% | 53,249 | 18.78 | +30.2% | +30.2% | +18.8% |
| 3.2.1 | 44,075 | 22.69 | -1.7% | +27.2% | 88,309 | 11.32 | +4.9% | +63.4% | +100.4% | 55,028 | 18.17 | +3.3% | +34.6% | +24.8% |
| 3.3.5 | 68,050 | 14.70 | +54.4% | +96.4% | 133,833 | 7.47 | +51.6% | +147.6% | +96.7% | 88,472 | 11.30 | +60.8% | +116.3% | +30.0% |
| 4.0.0 | 122,414 | 8.17 | +79.9% | +253.3% | 228,069 | 4.38 | +70.4% | +321.9% | +86.3% | 153,183 | 6.53 | +73.1% | +274.6% | +25.1% |
| master | 121,325 | 8.24 | -0.9% | +250.2% | 225,823 | 4.43 | -1.0% | +317.8% | +86.1% | 145,129 | 6.89 | -5.3% | +254.9% | +19.6% |

Over time, 3.0.1 → master: **+250.2%** without a JIT, **+317.8%** with YJIT, **+254.9%** with ZJIT.

## Notes
- All versions exercised through the same `BenchAPI` definition (kept stable in `app.rb`).
- `vs prev` compares throughput against the previous benched version and `vs 3.0.1` against the first one; read those columns for improvement over time.
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `<JIT> speedup` is that JIT's throughput against the No JIT pass on the same row.
- JIT passes use `ruby --yjit` and `ruby --zjit`; every pass shares the same Ruby binary. Only one JIT can be enabled at a time, so each gets its own pass.
