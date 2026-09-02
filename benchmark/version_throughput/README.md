# version_throughput

Cross-version throughput benchmark for Grape. Measures `BenchAPI.call(env)` requests-per-second for a tiny JSON endpoint, against the same `app.rb` definition exec'd under several Grape releases plus `master`. Used to track regressions and validate refactor wins.

## Files

| File | Role |
|---|---|
| `app.rb` | The API under test. Kept deliberately small and version-agnostic — only DSL surface stable across Grape 3.x, so the same file can run against `3.0.0 … master` without edits. |
| `bench.rb` | Single-version benchmark. Loads `app.rb`, sanity-checks the response, runs `Benchmark.ips` (2s warmup + 5s measure), prints one `RESULT,<ips>,<μs>,<stddev>,<yjit>` line for the orchestrator. |
| `run.rb` | Orchestrator. For each version: writes a `Gemfile`, runs `bundle install` under `tmp/bench-versions/<version>/`, exec's `bench.rb` once without YJIT and once with `--yjit` (if available), parses results, writes `RESULTS.md`. |
| `RESULTS.md` | Generated report — overwritten on every run. |

## Usage

```sh
# default: 3.0.0, 3.1.0, 3.2.0, 3.3.0, 3.3.5, master
ruby benchmark/version_throughput/run.rb

# subset
GRAPE_VERSIONS="3.3.5,master" ruby benchmark/version_throughput/run.rb

# different Ruby (e.g. one built with YJIT)
RBENV_VERSION=4.0.3 ruby benchmark/version_throughput/run.rb
```

`master` is benched against the working tree (`gemspec path: <repo root>`), so unstaged changes are picked up. All other versions resolve to released gems on rubygems.org.

## Output

Each version produces a row in `RESULTS.md`, listed oldest to newest so the table reads as a timeline:

| Version | No-YJIT (i/s) | μs/req | vs prev | vs 3.0.0 | YJIT (i/s) | μs/req | vs prev | vs 3.0.0 | YJIT speedup |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| … | … | … | … | … | … | … | … | … | … |

The two delta columns per pass are the point of the report: `vs prev` is the release-over-release change, `vs <first>` the cumulative change since the oldest benched version (the header names it — `vs 3.0.0` with the default list, whatever comes first in `GRAPE_VERSIONS` otherwise). A one-line summary under the table restates first → last for both passes.

YJIT columns are only emitted if the running Ruby was built with YJIT support (`run.rb` probes via `ruby --yjit -e 'exit(defined?(RubyVM::YJIT) ? 0 : 1)'`). Without YJIT the table keeps its `± stddev` column and still carries both deltas.

## Interpreting results

- **Noise floor is ~5-8%.** A single 5s window on macOS can easily move a few percent under thermal throttling or background load. Rerun before drawing conclusions on small deltas.
- **Run on a quiet machine.** Close other apps, plug in the laptop, don't touch the keyboard during the run. Each version takes ~14s of wall-clock measurement plus bundle install on first use.
- **`master` vs released gems is not apples-to-apples for code paths that changed.** If a refactor moved code between files, both numbers still measure the same `app.rb` request — that's the point — but interpret deltas as "end-to-end request cost" rather than per-method.
- **YJIT speedup is `(yjit_ips - no_yjit_ips) / no_yjit_ips`.** Both passes share the same Ruby binary; only the `--yjit` flag differs.
- **Deltas are computed per pass, on i/s.** A version that failed to bench is skipped as a reference, so `vs prev` always points at the closest version that actually produced a number — an `error:` row never breaks the chain.
- **Cumulative deltas compound the noise floor.** Read `vs 3.0.0` for the shape of the trend, not as a precise figure.

## Adding a version

Edit `DEFAULT_VERSIONS` in `run.rb`, keeping it in release order — the delta columns assume the list runs oldest to newest. The orchestrator handles `bundle install` and gemfile generation; nothing else needs to change as long as the new version exposes the DSL `app.rb` uses (`prefix`, `format`, `version 'v1', using: :path`, `get`).
