# frozen_string_literal: true

# Single-version throughput bench. Invoked by `run.rb` once per route shape
# and JIT mode for each Grape version. Loads `app.rb` (which is what gets
# compared across versions), sanity-checks the scenario named by the first
# argument, then prints a single
# `RESULT,<scenario>,<ips>,<us_per_iter>,<stddev_pct>,<jit>` line the
# orchestrator parses.
$LOAD_PATH.unshift(File.expand_path('.', __dir__))
require 'benchmark/ips'
require 'app'

SCENARIOS = {
  'static' => { api: StaticRouteBenchAPI, path: '/api/v1/hello' }.freeze,
  'parameterized' => { api: ParameterizedRouteBenchAPI, path: '/api/v1/hello/42' }.freeze,
  'many_static' => { api: ManyStaticRoutesBenchAPI, path: '/api/v1/resource199' }.freeze,
  'many_parameterized' => { api: ManyParameterizedRoutesBenchAPI, path: '/api/v1/resource199/42' }.freeze
}.freeze

scenario_name = ARGV.fetch(0, 'static')
scenario = SCENARIOS.fetch(scenario_name) do
  abort "unknown scenario #{scenario_name.inspect}; choose one of: #{SCENARIOS.keys.join(', ')}"
end
api = scenario.fetch(:api)
env_template = Rack::MockRequest.env_for(scenario.fetch(:path), method: Rack::GET).freeze

# Sanity check: 200 OK, body contains expected payload
status, _, body = api.call(env_template.dup)
abort("sanity check failed for #{scenario_name}: status=#{status}") unless status == 200
collected = +''
body.each { |c| collected << c }
abort("sanity check failed for #{scenario_name}: body=#{collected.inspect}") unless collected.include?('world')

report = Benchmark.ips do |ips|
  ips.config(time: 5, warmup: 2, quiet: true)
  ips.report(scenario_name) { api.call(env_template.dup) }
end

entry = report.entries.first

# Which JIT actually ran, so the orchestrator can confirm the flag it passed
# took effect rather than trusting a silently ignored one. Only one can be
# enabled at a time -- Ruby refuses to boot with both flags.
jit = %w[YJIT ZJIT].find { |mod| RubyVM.const_defined?(mod) && RubyVM.const_get(mod).enabled? } || 'none'
puts format('RESULT,%s,%.2f,%.4f,%.2f,%s', scenario_name, entry.ips, 1_000_000.0 / entry.ips, entry.error_percentage, jit.downcase)
