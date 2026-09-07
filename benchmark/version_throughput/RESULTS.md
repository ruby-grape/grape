# Grape throughput by version

Generated: 2026-09-07 18:16:50 CEST  
Ruby: ruby 4.0.6 (2026-07-14 revision 03b6d3f889) +PRISM [arm64-darwin25]  
Host: Darwin 25.6.0 arm64  
YJIT available: true

Single-threaded `Benchmark.ips`, 2s warmup + 5s measure, `BenchAPI.call(env)` against `/api/v1/hello` returning a small JSON object. Reproduce with `ruby benchmark/version_throughput/run.rb`.

| Version | No-YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 3.0.1 | 34,255 | 29.19 | — | — | 54,997 | 18.18 | — | — | +60.6% |
| 3.1.1 | 43,711 | 22.88 | +27.6% | +27.6% | 84,743 | 11.80 | +54.1% | +54.1% | +93.9% |
| 3.2.1 | 45,470 | 21.99 | +4.0% | +32.7% | 89,697 | 11.15 | +5.8% | +63.1% | +97.3% |
| 3.3.5 | 67,602 | 14.79 | +48.7% | +97.3% | 135,813 | 7.36 | +51.4% | +146.9% | +100.9% |
| 4.0.0 | 123,107 | 8.12 | +82.1% | +259.4% | 233,841 | 4.28 | +72.2% | +325.2% | +89.9% |
| master | 122,134 | 8.19 | -0.8% | +256.5% | 235,134 | 4.25 | +0.6% | +327.5% | +92.5% |

Over time, 3.0.1 → master: **+256.5%** without YJIT, **+327.5%** with YJIT.

## Notes
- All versions exercised through the same `BenchAPI` definition (kept stable in `app.rb`).
- `vs prev` compares throughput against the previous benched version and `vs 3.0.1` against the first one; read those columns for improvement over time.
- Results are noisy at this scale (±5-8%); rerun if a number looks off.
- `YJIT speedup` is `(yjit_ips - no_yjit_ips) / no_yjit_ips`.
- YJIT pass uses `ruby --yjit`; both passes share the same Ruby binary.
