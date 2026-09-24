# grape_on_rack

The [grape-on-rack](https://github.com/ruby-grape/grape-on-rack) example app, served by Puma against this checkout's `lib`, for memory-profiling Grape under a live web server. `profile_api_calls.rb` drives it with parallel HTTP requests covering every mounted API.

## Files

| File | Role |
|---|---|
| `Gemfile` | Resolves `grape` from the repository root (`path: '../..'`), so unstaged changes are picked up. |
| `config.ru` | Loads the APIs, compiles `Acme::API` before serving, runs `Acme::App`. |
| `api/` | One mounted `Grape::API` per feature: JSON in and out, path and header versioning, content types, entities, headers, `rescue_from`, streaming, uploads, a wrapping middleware. |
| `app/` | `Acme::API` mounts them under `/api`. `Acme::App` puts `Rack::Cors` in front and serves `public/` when the API answers with `X-Cascade: pass` or a 404/500. |
| `profile_api_calls.rb` | Load generator: a thread pool that runs every test case `TOTAL_ITERATIONS` times and prints a status-code breakdown. |

## Usage

```sh
cd benchmark/grape_on_rack
bundle install

# terminal 1: the server, under the profiler
ruby-memory-profiler --pretty --out=latest_cache.txt --allow-files=grape/lib run -- bundle exec rackup --env none

# terminal 2: the load
ruby profile_api_calls.rb

# terminal 1: Ctrl-C; the report is written to latest_cache.txt as the server exits
```

`ruby-memory-profiler` comes with the `memory_profiler` gem, installed outside the bundle: its `run` command loads itself through `RUBYOPT` and writes the report from an `at_exit` hook. It traces the whole process, so the report covers boot and route compilation as well as the requests.

`--allow-files=grape/lib` matches on the file path, so it keeps only this repository's `lib` when the checkout directory is named `grape`. Pass `--allow-files=<checkout dir>/lib` otherwise.

`--env none` keeps `rackup` from wrapping the app in its `development` middleware (`Rack::Lint`, `Rack::ShowExceptions`, `Rack::CommonLogger`, …), so Grape sees requests the way it would behind a production server.

`API_BASE_URL`, `THREAD_POOL_SIZE` and `TOTAL_ITERATIONS` configure the load, see the header of `profile_api_calls.rb`. The stream endpoint sleeps 1.5 s per request, which sets most of the run time.

Reports are `*.txt` and ignored by git.
