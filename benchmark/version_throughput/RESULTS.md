# Grape throughput by version

Generated: 2026-06-14 13:30:05 CEST  
Ruby: ruby 4.0.5 (2026-05-20 revision 64336ffd0e) +PRISM [arm64-darwin25]  
Host: Darwin 25.5.0 arm64  
Machine: MacBook Pro (Mac14,9), Apple M2 Pro, 10 cores (6P + 4E), 32 GB RAM  
YJIT available: true

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure, `BenchAPI.call(env)` against `/api/v1/hello` returning a small JSON object. Reproduce with `ruby benchmark/version_throughput/run.rb`.

| Version | No-YJIT (i/s) | μs/req | YJIT (i/s) | μs/req | YJIT speedup |
|---|---:|---:|---:|---:|---:|
| 3.0.1 | 32,565 | 30.71 | 54,940 | 18.20 | +68.7% |
| 3.1.1 | 46,641 | 21.44 | 85,694 | 11.67 | +83.7% |
| 3.2.1 | 47,929 | 20.86 | 85,328 | 11.72 | +78.0% |
| master | 66,149 | 15.12 | 133,760 | 7.48 | +102.2% |

## Notes
- All versions exercised through the same `BenchAPI` definition (kept stable in `app.rb`).
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `YJIT speedup` is `(yjit_ips - no_yjit_ips) / no_yjit_ips`.
- YJIT pass uses `ruby --yjit`; both passes share the same Ruby binary.
