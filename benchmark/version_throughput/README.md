# version_throughput

Cross-version throughput benchmark for Grape. Measures `BenchAPI.call(env)` requests-per-second for a tiny JSON endpoint, against the same `app.rb` definition exec'd under several Grape releases plus `master`. Used to track regressions and validate refactor wins.

## Files

| File | Role |
|---|---|
| `app.rb` | The API under test. Kept deliberately small and version-agnostic — only DSL surface stable across Grape 3.x, so the same file can run against `3.0.1 … master` without edits. |
| `bench.rb` | Single-version benchmark. Loads `app.rb`, sanity-checks the response, runs `Benchmark.ips` (2s warmup + 5s measure), prints one `RESULT,<ips>,<μs>,<stddev>,<jit>` line for the orchestrator. The trailing field names the JIT that was actually enabled, so the orchestrator can tell a flag that took effect from one that was silently ignored. |
| `run.rb` | Orchestrator. For each version: writes a `Gemfile`, runs `bundle install` under `tmp/bench-versions/<version>/`, exec's `bench.rb` once per available JIT mode — plain, `--yjit`, `--zjit` — parses results, writes `RESULTS.md`. |
| `RESULTS.md` | Generated report — overwritten on every run. |

## Usage

```sh
# default: 3.0.1, 3.1.1, 3.2.1, 3.3.5, 4.0.0, master
ruby benchmark/version_throughput/run.rb

# subset
GRAPE_VERSIONS="3.3.5,master" ruby benchmark/version_throughput/run.rb

# different Ruby (e.g. one built with YJIT/ZJIT)
RBENV_VERSION=4.0.6 ruby benchmark/version_throughput/run.rb
```

`master` is benched against the working tree (`gemspec path: <repo root>`), so unstaged changes are picked up. All other versions resolve to released gems on rubygems.org.

## Output

Each version produces a row in `RESULTS.md`, listed oldest to newest so the table reads as a timeline:

| Version | No JIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT (i/s) | μs/req | vs prev | vs 3.0.1 | YJIT speedup | ZJIT (i/s) | μs/req | vs prev | vs 3.0.1 | ZJIT speedup |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| … | … | … | … | … | … | … | … | … | … | … | … | … | … | … |

The two delta columns per pass are the point of the report: `vs prev` is the release-over-release change, `vs <first>` the cumulative change since the oldest benched version (the header names it — `vs 3.0.1` with the default list, whatever comes first in `GRAPE_VERSIONS` otherwise). A one-line summary under the table restates first → last for both passes.

A JIT's columns are only emitted if the running Ruby can actually run it: `run.rb` boots `ruby <flag>` and checks `RubyVM::YJIT.enabled?` / `RubyVM::ZJIT.enabled?`, not merely that the constant exists — both are defined on a supporting build whether or not the flag was given. With no JIT available the table falls back to the compact layout, keeping its `± stddev` column and both deltas.

## Interpreting results

- **Noise floor is ~5-8%.** A single 5s window on macOS can easily move a few percent under thermal throttling or background load. Rerun before drawing conclusions on small deltas.
- **`master` right after a release benches the same code twice.** When nothing has landed on `master` since the newest benched release, the two rows exercise identical code and their spread is a direct read of that session's noise floor — not a regression or a win.
- **Run on a quiet machine.** Close other apps, plug in the laptop, don't touch the keyboard during the run. Each version takes ~14s of wall-clock measurement plus bundle install on first use.
- **`master` vs released gems is not apples-to-apples for code paths that changed.** If a refactor moved code between files, both numbers still measure the same `app.rb` request — that's the point — but interpret deltas as "end-to-end request cost" rather than per-method.
- **A JIT's speedup is measured against the No JIT pass on the same row.** Every pass shares the same Ruby binary; only the JIT flag differs. Ruby refuses to boot with both `--yjit` and `--zjit`, so each JIT gets its own pass rather than being stacked.
- **Deltas are computed per pass, on i/s.** A version that failed to bench is skipped as a reference, so `vs prev` always points at the closest version that actually produced a number — an `error:` row never breaks the chain.
- **Cumulative deltas compound the noise floor.** Read `vs 3.0.1` for the shape of the trend, not as a precise figure.

## Why ZJIT trails YJIT

ZJIT comes out well ahead of the interpreter but well behind YJIT — roughly +20% against +86% on `master`. That gap is ZJIT's codegen, not the harness. Measured on Ruby 4.0.6; re-check before assuming it still holds, because the answer is expected to move as ZJIT matures.

What was ruled out:

- **Warmup.** Throughput is flat from a 2s to a 20s warmup in both JITs. Both trigger at 30 calls (`--yjit-call-threshold`, `--zjit-call-threshold`), which a 5s measure passes in the first millisecond.
- **Compilation.** `compiled_iseq_count: 306` with `failed_iseq_count: 0` — ZJIT compiled the whole request path.
- **Deoptimisation.** `guard_type_exit_ratio: 0.0%`, `guard_shape_exit_ratio: 2.7%`, ~4 side exits per request.
- **Grape.** A small non-Grape JSON workload on the same Ruby shows the same ordering, just with narrower margins.

What `--zjit-stats` does show is about 30 uninlined C method calls per request, and the list is the set YJIT emits inline codegen for:

```
String#include?  Array#any?     Array#to_a   Array#include?
Regexp#match     Kernel#dup     Hash#fetch   String#to_sym
```

Only ~36% of sends take an inlined cfunc path, and each uninlined one syncs interpreter state before the call — `vm_write_pc_count` and `vm_write_sp_count` both land near 167 per request. Grape's request path is dispatch-heavy and leans on exactly those core methods, so the gap shows up wider here than on C-bound code.

Reproduce with a fixed call count rather than `Benchmark.ips`, so the counters are per-request:

```sh
BUNDLE_GEMFILE=tmp/bench-versions/master/Gemfile \
  bundle exec ruby --zjit --zjit-stats -e '
    $LOAD_PATH.unshift("benchmark/version_throughput"); require "app"
    env = Rack::MockRequest.env_for("/api/v1/hello", method: Rack::GET).freeze
    300_000.times { BenchAPI.call(env.dup) }'
```

## Adding a version

Edit `DEFAULT_VERSIONS` in `run.rb`, keeping it in release order — the delta columns assume the list runs oldest to newest. The orchestrator handles `bundle install` and gemfile generation; nothing else needs to change as long as the new version exposes the DSL `app.rb` uses (`prefix`, `format`, `version 'v1', using: :path`, `get`).
