# Benchmarks

- [version_throughput](version_throughput) compares Grape's releases and `master` with each other.
- [grape_on_rack](grape_on_rack) profiles memory under a live server.
- The single-file scripts run with `bundle exec ruby benchmark/<name>.rb`.

The traps below were found measuring Grape on Ruby 4.0. Each one made an A/B look like a regression, or a benchmark measure nothing.

## Measuring a change

- **A/B from one checkout.** Two checkouts of the same commit at different paths measured 5% apart under YJIT. Check out each side in turn in the same worktree, alternate which side runs first, and report the median of the per-round ratios with the rounds won. One bad round drags a mean.
- **Know the noise.** An A/A of identical code on the interpreter read medians from −0.2% to +3.0%. Treat a residue under about 3% as noise until an A/A says otherwise.
- **Size a regression by the work done.** Count the calls a request makes on each side with `TracePoint.new(:call, :c_call, :b_call)`, and diff them. One Ruby method call costs about 14 ns on the interpreter and under 1 ns with YJIT.
- **`compile!` is memoized.** After its first call it returns the compiled instance, so a loop over `API.compile!` times nothing. Build afresh with `API.send(:base_instance).new` instead, and give that a longer benchmark-ips window.

## Profiling

- **stackprof overstates GC.** It put about 44% of a bare request in `(sweeping)` and `(garbage collection)`, while disabling GC around the same loop made it only 0.1–2.6% faster. Profile with `ignore_gc: true`, and measure GC with `GC.stat[:time]` or a `GC.disable` A/B.
- **YJIT microbenchmarks.** A loop bounded by a top-level constant ran at interpreter speed under YJIT; bound it with a local or an argument. YJIT compiles a method only after 30 calls, so pass `--yjit-call-threshold=1` to short runs.

## Allocations

- `str[a...b]` with variable bounds allocates a Range as well as the String; `str[a, b - a]` allocates only the String. Array slices behave the same way.
- A `return` from inside a block allocates on the path that returns; a `while` loop doesn't.
- `hash.each_key.none? { … }` builds an Enumerator and is slower than `hash.keys.none? { … }`.
- String interpolation inside a predicate block allocates once per element; hoist it out of the block.
- An object's slot size (40, 80, 160, 320 or 640 bytes) comes from the most instance variables any instance of its exact class has held, `dup` included. A `Grape::Endpoint` is copied per request, so an instance variable that a route block sets enlarges every copy. Check with `ObjectSpace.memsize_of`.
