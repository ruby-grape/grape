# Grape throughput by version

Generated: 2026-09-02 10:52:37 CEST  
Ruby: ruby 4.0.5 (2026-05-20 revision 64336ffd0e) +PRISM [arm64-darwin25]  
Host: Darwin 25.6.0 arm64  
YJIT available: true

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure, `BenchAPI.call(env)` against `/api/v1/hello` returning a small JSON object. Reproduce with `ruby benchmark/version_throughput/run.rb`.

| Version | No-YJIT (i/s) | μs/req | vs prev | vs 3.0.0 | YJIT (i/s) | μs/req | vs prev | vs 3.0.0 | YJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.0 | 34,131 | 29.30 | — | — | 55,526 | 18.01 | — | — | +62.7% |
| 3.1.0 | 44,425 | 22.51 | +30.2% | +30.2% | 83,543 | 11.97 | +50.5% | +50.5% | +88.1% |
| 3.2.0 | 46,148 | 21.67 | +3.9% | +35.2% | 85,855 | 11.65 | +2.8% | +54.6% | +86.0% |
| 3.3.0 | 64,641 | 15.47 | +40.1% | +89.4% | 134,888 | 7.41 | +57.1% | +142.9% | +108.7% |
| 3.3.5 | 64,426 | 15.52 | -0.3% | +88.8% | 134,141 | 7.45 | -0.6% | +141.6% | +108.2% |
| master | 87,364 | 11.45 | +35.6% | +156.0% | 180,159 | 5.55 | +34.3% | +224.5% | +106.2% |

Over time, 3.0.0 → master: **+156.0%** without YJIT, **+224.5%** with YJIT.

## Notes
- All versions exercised through the same `BenchAPI` definition (kept stable in `app.rb`).
- `vs prev` compares throughput against the previous benched version and `vs 3.0.0` against the first one; read those columns for improvement over time.
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `YJIT speedup` is `(yjit_ips - no_yjit_ips) / no_yjit_ips`.
- YJIT pass uses `ruby --yjit`; both passes share the same Ruby binary.
