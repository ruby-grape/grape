# frozen_string_literal: true

# Single-version throughput bench. Invoked once per Grape version by
# `run.rb`. Loads `app.rb` (which is what gets compared across versions),
# warms up, then prints a single `RESULT,<ips>,<us_per_iter>,<stddev_pct>`
# line the orchestrator parses.
$LOAD_PATH.unshift(File.expand_path('.', __dir__))
require 'benchmark/ips'
require 'app'

env_template = Rack::MockRequest.env_for('/api/v1/hello', method: Rack::GET).freeze

# Sanity check: 200 OK, body contains expected payload
status, _, body = BenchAPI.call(env_template.dup)
abort("sanity check failed: status=#{status}") unless status == 200
collected = +''
body.each { |c| collected << c }
abort("sanity check failed: body=#{collected.inspect}") unless collected.include?('world')

report = Benchmark.ips do |ips|
  ips.config(time: 5, warmup: 2, quiet: true)
  ips.report('throughput') { BenchAPI.call(env_template.dup) }
end

entry = report.entries.first
yjit = (defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?) ? 'on' : 'off'
puts format('RESULT,%.2f,%.4f,%.2f,%s', entry.ips, 1_000_000.0 / entry.ips, entry.error_percentage, yjit)
