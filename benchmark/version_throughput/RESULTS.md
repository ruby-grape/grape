# Grape throughput by version

Generated: 2026-09-07 17:13:53 CEST  
Ruby: ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin25]  
Host: Darwin 25.6.0 arm64  
YJIT available: true

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure, `BenchAPI.call(env)` against `/api/v1/hello` returning a small JSON object. Reproduce with `ruby benchmark/version_throughput/run.rb`.

| Version | No-YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 34,512 | 28.98 | — | — | 52,487 | 19.05 | — | — | +52.1% |
| 3.1.1 | 45,656 | 21.90 | +32.3% | +32.3% | 85,284 | 11.73 | +62.5% | +62.5% | +86.8% |
| 3.2.1 | 47,440 | 21.08 | +3.9% | +37.5% | 90,745 | 11.02 | +6.4% | +72.9% | +91.3% |
| 3.3.5 | 67,834 | 14.74 | +43.0% | +96.6% | 137,675 | 7.26 | +51.7% | +162.3% | +103.0% |
| master | 120,877 | 8.27 | +78.2% | +250.2% | 230,153 | 4.34 | +67.2% | +338.5% | +90.4% |

Over time, 3.0.1 → master: **+250.2%** without YJIT, **+338.5%** with YJIT.

## Notes
- All versions exercised through the same `BenchAPI` definition (kept stable in `app.rb`).
- `vs prev` compares throughput against the previous benched version and `vs 3.0.1` against the first one; read those columns for improvement over time.
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `YJIT speedup` is `(yjit_ips - no_yjit_ips) / no_yjit_ips`.
- YJIT pass uses `ruby --yjit`; both passes share the same Ruby binary.
