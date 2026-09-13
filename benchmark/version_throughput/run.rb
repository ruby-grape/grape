# frozen_string_literal: true

# Orchestrator: runs benchmark/version_throughput/bench.rb for each route
# shape against each Grape version listed below in a clean subprocess (one
# bundle per version under tmp/), parses the RESULT lines, and writes Markdown
# tables to benchmark/version_throughput/RESULTS.md.
#
# Each route shape is benched once per JIT mode the running Ruby supports: the
# plain interpreter, `--yjit` and `--zjit`. Each pass reports throughput plus
# two deltas — against the previous benched version and against the first one
# — so every table reads as improvement over time, and each JIT pass also
# reports its speedup over the interpreter on the same version.
#
# Usage:
#   ruby benchmark/version_throughput/run.rb
#
# To bench against a specific subset:
#   GRAPE_VERSIONS="3.0.1,3.3.5,master" ruby benchmark/version_throughput/run.rb
#
# To bench selected route shapes:
#   GRAPE_SCENARIOS="static,parameterized" ruby benchmark/version_throughput/run.rb
#
# Versions must be listed oldest to newest: the delta columns compare each
# row against the one above it and against the first row.
#
# To run a JIT-enabled Ruby that isn't the project default:
#   RBENV_VERSION=4.0.6 ruby benchmark/version_throughput/run.rb

require 'fileutils'
require 'open3'
require 'rbconfig'

ROOT = File.expand_path('../..', __dir__)
HERE = __dir__
TMP  = File.join(ROOT, 'tmp', 'bench-versions')

DEFAULT_VERSIONS = %w[3.0.1 3.1.1 3.2.1 3.3.5 4.0.0 master].freeze
versions = (ENV['GRAPE_VERSIONS']&.split(',')&.map(&:strip) || DEFAULT_VERSIONS).freeze

# One pass per JIT mode, in report column order. +flag+ is what `ruby` is
# invoked with (none for the interpreter), +key+ is where the pass is recorded
# in +results+, and +jit+ is what bench.rb reports back once it is running, so
# a flag that was accepted but did nothing can be caught rather than published
# as a JIT column that merely repeats the interpreter's number.
JIT_MODES = [
  { key: :none, flag: nil, label: 'No JIT', jit: 'none' },
  { key: :yjit, flag: '--yjit', label: 'YJIT', jit: 'yjit' },
  { key: :zjit, flag: '--zjit', label: 'ZJIT', jit: 'zjit' }
].freeze

SCENARIO_DEFINITIONS = [
  {
    key: 'static',
    label: 'Static route',
    description: '`GET /api/v1/hello` against one literal, path-versioned route.'
  }.freeze,
  {
    key: 'parameterized',
    label: 'Parameterized route',
    description: '`GET /api/v1/hello/42` against a path-versioned `get \'/hello/:id\'` route.'
  }.freeze,
  {
    key: 'many_static',
    label: 'Many static routes',
    description: '`GET /api/v1/resource199`, the last of 200 literal, path-versioned routes.'
  }.freeze,
  {
    key: 'many_parameterized',
    label: 'Many parameterized routes',
    description: '`GET /api/v1/resource199/42`, the last of 200 path-versioned `get \'/resourceN/:id\'` routes.'
  }.freeze
].freeze

requested_scenarios = ENV.fetch('GRAPE_SCENARIOS', '').split(',').map(&:strip).reject(&:empty?)
scenario_keys = SCENARIO_DEFINITIONS.map { |scenario| scenario.fetch(:key) }
unknown_scenarios = requested_scenarios - scenario_keys
abort "unknown scenarios: #{unknown_scenarios.join(', ')}" unless unknown_scenarios.empty?

scenarios = if requested_scenarios.empty?
              SCENARIO_DEFINITIONS
            else
              requested_scenarios.map { |key| SCENARIO_DEFINITIONS.find { |scenario| scenario.fetch(:key) == key } }
            end

def gemfile_for(version)
  if version == 'master'
    <<~G
      source 'https://rubygems.org'
      gemspec path: '#{ROOT}'
      gem 'benchmark-ips'
    G
  else
    <<~G
      source 'https://rubygems.org'
      gem 'grape', '#{version}'
      gem 'benchmark-ips'
      gem 'rack'
    G
  end
end

def prepare(version)
  dir = File.join(TMP, version)
  FileUtils.mkdir_p(dir)
  File.write(File.join(dir, 'Gemfile'), gemfile_for(version))
  dir
end

def run_bundle_install(dir)
  Open3.capture2e({ 'BUNDLE_GEMFILE' => File.join(dir, 'Gemfile') }, 'bundle', 'install', '--quiet', chdir: dir)
end

def run_bench(dir, flag, scenario)
  args = ['bundle', 'exec', 'ruby']
  args << flag if flag
  args << File.join(HERE, 'bench.rb')
  args << scenario.fetch(:key)
  Open3.capture2e({ 'BUNDLE_GEMFILE' => File.join(dir, 'Gemfile') }, *args)
end

def parse_result(stdout, scenario)
  line = stdout.lines.reverse.find { |l| l.start_with?('RESULT,') }
  return nil unless line

  _, scenario_key, ips, us, stddev, jit = line.strip.split(',')
  return nil unless scenario_key == scenario.fetch(:key)

  { ips: ips.to_f, us: us.to_f, stddev: stddev.to_f, jit: jit }
end

# The interpreter is always available; a JIT is only usable if the flag both
# boots and leaves the JIT actually enabled. Checking `enabled?` rather than
# the constant matters: RubyVM::YJIT and RubyVM::ZJIT are defined on a build
# that supports them whether or not the flag was given.
def jit_available?(mode)
  return true unless mode[:flag]

  _, status = Open3.capture2e('ruby', mode[:flag], '-e', "exit(RubyVM.const_get(:#{mode[:jit].upcase}).enabled? ? 0 : 1)")
  status.success?
end

modes = JIT_MODES.select { |mode| jit_available?(mode) }
jit_modes = modes.reject { |mode| mode[:key] == :none }
puts "JIT modes available in current Ruby: #{jit_modes.map { |mode| mode[:label] }.join(', ').then { |l| l.empty? ? 'none' : l }}"

results = scenarios.to_h { |scenario| [scenario.fetch(:key), {}] }
versions.each do |version|
  print "[#{version}] preparing... "
  dir = prepare(version)
  install_out, install_status = run_bundle_install(dir)
  unless install_status.success?
    puts "FAILED (bundle install)\n#{install_out}"
    scenarios.each do |scenario|
      results.fetch(scenario.fetch(:key))[version] = { error: 'bundle install failed' }
    end
    next
  end

  puts 'done'
  scenarios.each do |scenario|
    scenario_results = results.fetch(scenario.fetch(:key))
    scenario_results[version] = {}
    print "[#{version}] #{scenario.fetch(:label)}: "

    modes.each do |mode|
      print "#{mode[:label]}... "
      bench_out, bench_status = run_bench(dir, mode[:flag], scenario)
      parsed = parse_result(bench_out, scenario) if bench_status.success?

      if parsed.nil?
        print 'FAILED  '
        scenario_results[version][mode[:key]] = { error: bench_status.success? ? 'no RESULT line' : 'bench failed', stdout: bench_out }
      elsif parsed[:jit] != mode[:jit]
        print "MISMATCH (ran under #{parsed[:jit]})  "
        scenario_results[version][mode[:key]] = { error: "expected #{mode[:jit]}, ran under #{parsed[:jit]}" }
      else
        scenario_results[version][mode[:key]] = parsed
        printf('%.0f i/s  ', parsed[:ips])
      end
    end
    puts
  end
end

# Write Markdown report
ruby_desc = `ruby -e 'puts RUBY_DESCRIPTION'`.strip
host_desc = `uname -mrs 2>/dev/null`.strip
report_path = File.join(HERE, 'RESULTS.md')

format_ips = ->(n) { n.round.to_s.reverse.scan(/\d{1,3}/).join(',').reverse }
ips_cell    = ->(pass) { pass&.dig(:ips)    ? format_ips.call(pass[:ips]) : 'err' }
us_cell     = ->(pass) { pass&.dig(:us)     ? format('%.2f', pass[:us]) : '' }
stddev_cell = ->(pass) { pass&.dig(:stddev) ? format('±%.2f%%', pass[:stddev]) : '' }

percent = lambda do |current, reference|
  return '—' unless current && reference&.positive?

  format('%+.1f%%', (current - reference) / reference * 100.0)
end

File.open(report_path, 'w') do |f|
  row = ->(cells) { f.puts("| #{cells.join(' | ')} |") }

  f.puts "# Grape route throughput by version\n\n"
  f.puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')}  "
  f.puts "Ruby: #{ruby_desc}  "
  f.puts "Host: #{host_desc}  "
  f.puts "JIT modes benched: #{modes.map { |mode| mode[:label] }.join(', ')}\n\n"
  f.puts 'Single-threaded `Benchmark.ips`, 2s warmup + 5s measure. Each route shape has an independent table, ' \
         'so a static-route fast path cannot be mistaken for general request throughput. ' \
         'Reproduce with `ruby benchmark/version_throughput/run.rb`.'

  scenarios.each do |scenario|
    scenario_results = results.fetch(scenario.fetch(:key))
    ips_of = ->(version, pass) { scenario_results.dig(version, pass, :ips) }
    previous_of = lambda do |version, pass|
      versions[0...versions.index(version)].reverse_each.find { |v| ips_of.call(v, pass) }
    end
    baseline_of = ->(pass) { versions.find { |v| ips_of.call(v, pass) } }
    deltas_of = lambda do |version, pass|
      current = ips_of.call(version, pass)
      previous = previous_of.call(version, pass)
      baseline = baseline_of.call(pass)
      [
        previous ? percent.call(current, ips_of.call(previous, pass)) : '—',
        baseline && baseline != version ? percent.call(current, ips_of.call(baseline, pass)) : '—'
      ]
    end
    first_version = modes.filter_map { |mode| baseline_of.call(mode[:key]) }.first || versions.first
    last_version = versions.reverse_each.find { |v| modes.any? { |mode| ips_of.call(v, mode[:key]) } }
    headers =
      if jit_modes.empty?
        ['Version', 'Throughput (i/s)', 'μs/req', '± stddev', 'vs prev', "vs #{first_version}"]
      else
        ['Version', 'No JIT (i/s)', 'μs/req', 'vs prev', "vs #{first_version}"] +
          jit_modes.flat_map do |mode|
            ["#{mode[:label]} (i/s)", 'μs/req', 'vs prev', "vs #{first_version}", "#{mode[:label]} speedup"]
          end
      end
    row_for = lambda do |version|
      route_results = scenario_results.fetch(version)
      return [version, "error: #{route_results[:error]}"] + Array.new(headers.size - 2, '') if route_results[:error]

      base = route_results[:none]
      head = [version, ips_cell.call(base), us_cell.call(base)]
      return head + [stddev_cell.call(base)] + deltas_of.call(version, :none) if jit_modes.empty?

      head + deltas_of.call(version, :none) +
        jit_modes.flat_map do |mode|
          pass = route_results[mode[:key]]
          [ips_cell.call(pass), us_cell.call(pass)] + deltas_of.call(version, mode[:key]) +
            [percent.call(pass&.dig(:ips), base&.dig(:ips))]
        end
    end
    overall = modes.filter_map do |mode|
      current = ips_of.call(last_version, mode[:key])
      reference = ips_of.call(first_version, mode[:key])
      next unless current && reference && last_version != first_version

      "**#{percent.call(current, reference)}** #{mode[:key] == :none ? 'without a JIT' : "with #{mode[:label]}"}"
    end

    f.puts "\n## #{scenario.fetch(:label)}\n\n#{scenario.fetch(:description)}\n\n"
    row.call(headers)
    row.call(['---'] + Array.new(headers.size - 1, '---:'))
    versions.each { |version| row.call(row_for.call(version)) }
    f.puts "\nOver time, #{first_version} → #{last_version}: #{overall.join(', ')}." unless overall.empty?
  end

  f.puts "\n## Notes"
  f.puts '- All versions exercise the same route-shape APIs, kept stable in `app.rb`.'
  f.puts '- `vs prev` compares throughput against the previous benched version and `vs <first>` against the oldest one ' \
         'in the same table; read those columns for improvement over time.'
  f.puts '- Compare a route shape across versions, not i/s across route shapes: a change that speeds up one shape, ' \
         'such as a lookup for literal paths, need not move the others.'
  f.puts '- Results are noisy at this scale (±5-8%); rerun if a number looks off.'
  unless jit_modes.empty?
    f.puts '- `<JIT> speedup` is that JIT\'s throughput against the No JIT pass on the same row.'
    f.puts "- JIT passes use #{jit_modes.map { |mode| "`ruby #{mode[:flag]}`" }.join(' and ')}; " \
           'every pass shares the same Ruby binary. Only one JIT can be enabled at a time, so each gets its own pass.'
  end
end

puts "\nWritten: #{report_path}"
