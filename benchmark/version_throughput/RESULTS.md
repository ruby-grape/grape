# Grape throughput by version

Generated: 2026-09-03 17:36:43 CEST  
Ruby: ruby 4.0.5 (2026-05-20 revision 64336ffd0e) +PRISM [arm64-darwin25]  
Host: Darwin 25.6.0 arm64  
YJIT available: true

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure, `BenchAPI.call(env)` against `/api/v1/hello` returning a small JSON object. Reproduce with `ruby benchmark/version_throughput/run.rb`.

| Version | No-YJIT (i/s) | μs/req | vs prev | vs 3.0.0 | YJIT (i/s) | μs/req | vs prev | vs 3.0.0 | YJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.0 | 34,888 | 28.66 | — | — | 54,534 | 18.34 | — | — | +56.3% |
| 3.1.0 | 46,167 | 21.66 | +32.3% | +32.3% | 81,978 | 12.20 | +50.3% | +50.3% | +77.6% |
| 3.2.0 | 47,607 | 21.01 | +3.1% | +36.5% | 87,016 | 11.49 | +6.1% | +59.6% | +82.8% |
| 3.3.0 | 67,541 | 14.81 | +41.9% | +93.6% | 131,704 | 7.59 | +51.4% | +141.5% | +95.0% |
| 3.3.5 | 66,677 | 15.00 | -1.3% | +91.1% | 134,236 | 7.45 | +1.9% | +146.2% | +101.3% |
| master | 118,545 | 8.44 | +77.8% | +239.8% | 224,272 | 4.46 | +67.1% | +311.3% | +89.2% |

Over time, 3.0.0 → master: **+239.8%** without YJIT, **+311.3%** with YJIT.

## Notes
- All versions exercised through the same `BenchAPI` definition (kept stable in `app.rb`).
- `vs prev` compares throughput against the previous benched version and `vs 3.0.0` against the first one; read those columns for improvement over time.
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `YJIT speedup` is `(yjit_ips - no_yjit_ips) / no_yjit_ips`.
- YJIT pass uses `ruby --yjit`; both passes share the same Ruby binary.
