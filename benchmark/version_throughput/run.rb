# frozen_string_literal: true

# Orchestrator: runs benchmark/version_throughput/bench.rb against each
# Grape version listed below in a clean subprocess (one bundle per version
# under tmp/), parses the RESULT line, and writes a Markdown table to
# benchmark/version_throughput/RESULTS.md.
#
# Each version is benched twice: once without YJIT, once with `--yjit`
# (skipped if the running Ruby wasn't built with YJIT). Each pass reports
# throughput plus two deltas — against the previous benched version and
# against the first one — so the table reads as improvement over time.
#
# Usage:
#   ruby benchmark/version_throughput/run.rb
#
# To bench against a specific subset:
#   GRAPE_VERSIONS="3.0.0,3.3.5,master" ruby benchmark/version_throughput/run.rb
#
# Versions must be listed oldest to newest: the delta columns compare each
# row against the one above it and against the first row.
#
# To run a YJIT-enabled Ruby that isn't the project default:
#   RBENV_VERSION=4.0.3 ruby benchmark/version_throughput/run.rb

require 'fileutils'
require 'open3'
require 'rbconfig'

ROOT = File.expand_path('../..', __dir__)
HERE = __dir__
TMP  = File.join(ROOT, 'tmp', 'bench-versions')

DEFAULT_VERSIONS = %w[3.0.0 3.1.0 3.2.0 3.3.0 3.3.5 master].freeze
versions = (ENV['GRAPE_VERSIONS']&.split(',')&.map(&:strip) || DEFAULT_VERSIONS).freeze

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

def run_bench(dir, yjit:)
  args = ['bundle', 'exec', 'ruby']
  args << '--yjit' if yjit
  args << File.join(HERE, 'bench.rb')
  Open3.capture2e({ 'BUNDLE_GEMFILE' => File.join(dir, 'Gemfile') }, *args)
end

def parse_result(stdout)
  line = stdout.lines.reverse.find { |l| l.start_with?('RESULT,') }
  return nil unless line

  _, ips, us, stddev, yjit = line.strip.split(',')
  { ips: ips.to_f, us: us.to_f, stddev: stddev.to_f, yjit: yjit }
end

def yjit_available?
  out, status = Open3.capture2e('ruby', '--yjit', '-e', 'exit(defined?(RubyVM::YJIT) ? 0 : 1)')
  status.success? && !out.include?('without YJIT support')
end

with_yjit = yjit_available?
puts "YJIT available in current Ruby: #{with_yjit}"

results = {}
versions.each do |version|
  print "[#{version}] preparing... "
  dir = prepare(version)
  install_out, install_status = run_bundle_install(dir)
  unless install_status.success?
    puts "FAILED (bundle install)\n#{install_out}"
    results[version] = { error: 'bundle install failed' }
    next
  end

  results[version] = {}

  # Pass 1: no YJIT
  print 'no-yjit... '
  bench_out, bench_status = run_bench(dir, yjit: false)
  if bench_status.success? && (parsed = parse_result(bench_out))
    results[version][:no_yjit] = parsed
    printf('%.0f i/s', parsed[:ips])
  else
    print 'FAILED'
    results[version][:no_yjit] = { error: bench_status.success? ? 'no RESULT line' : 'bench failed', stdout: bench_out }
  end

  # Pass 2: --yjit (skip if not available)
  if with_yjit
    print '  yjit... '
    bench_out, bench_status = run_bench(dir, yjit: true)
    if bench_status.success? && (parsed = parse_result(bench_out))
      results[version][:yjit] = parsed
      printf('%.0f i/s', parsed[:ips])
    else
      print 'FAILED'
      results[version][:yjit] = { error: bench_status.success? ? 'no RESULT line' : 'bench failed', stdout: bench_out }
    end
  end
  puts
end

# Write Markdown report
ruby_desc = `ruby -e 'puts RUBY_DESCRIPTION'`.strip
host_desc = `uname -mrs 2>/dev/null`.strip
report_path = File.join(HERE, 'RESULTS.md')

format_ips = ->(n) { n.round.to_s.reverse.scan(/\d{1,3}/).join(',').reverse }
ips_cell    = ->(pass) { pass&.dig(:ips)    ? format_ips.call(pass[:ips]) : 'err' }
us_cell     = ->(pass) { pass&.dig(:us)     ? format('%.2f', pass[:us]) : '' }
stddev_cell = ->(pass) { pass&.dig(:stddev) ? format('±%.2f%%', pass[:stddev]) : '' }

# Throughput of `version` in a given pass (:no_yjit / :yjit), or nil when it produced no number.
ips_of = ->(version, pass) { results.dig(version, pass, :ips) }

# Newest version benched before `version` in this pass — the reference of `vs prev`.
previous_of = lambda do |version, pass|
  versions[0...versions.index(version)].reverse_each.find { |v| ips_of.call(v, pass) }
end

# Oldest version benched in this pass — the reference of `vs <first>`.
baseline_of = ->(pass) { versions.find { |v| ips_of.call(v, pass) } }

percent = lambda do |current, reference|
  return '—' unless current && reference&.positive?

  format('%+.1f%%', (current - reference) / reference * 100.0)
end

# [vs previous version, vs first version] for one pass — the improvement-over-time columns.
deltas_of = lambda do |version, pass|
  current = ips_of.call(version, pass)
  previous = previous_of.call(version, pass)
  baseline = baseline_of.call(pass)
  [
    previous ? percent.call(current, ips_of.call(previous, pass)) : '—',
    baseline && baseline != version ? percent.call(current, ips_of.call(baseline, pass)) : '—'
  ]
end

first_version = baseline_of.call(:no_yjit) || baseline_of.call(:yjit) || versions.first
last_version = versions.reverse_each.find { |v| ips_of.call(v, :no_yjit) || ips_of.call(v, :yjit) }

headers =
  if with_yjit
    ['Version', 'No-YJIT (i/s)', 'μs/req', 'vs prev', "vs #{first_version}",
     'YJIT (i/s)', 'μs/req', 'vs prev', "vs #{first_version}", 'YJIT speedup']
  else
    ['Version', 'Throughput (i/s)', 'μs/req', '± stddev', 'vs prev', "vs #{first_version}"]
  end

row_for = lambda do |version|
  r = results[version]
  return [version, "error: #{r[:error]}"] + Array.new(headers.size - 2, '') if r.is_a?(Hash) && r[:error]

  no_yjit = r[:no_yjit]
  yjit = r[:yjit]
  head = [version, ips_cell.call(no_yjit), us_cell.call(no_yjit)]
  return head + [stddev_cell.call(no_yjit)] + deltas_of.call(version, :no_yjit) unless with_yjit

  head + deltas_of.call(version, :no_yjit) + [ips_cell.call(yjit), us_cell.call(yjit)] +
    deltas_of.call(version, :yjit) + [percent.call(yjit&.dig(:ips), no_yjit&.dig(:ips))]
end

# One-line summary of the whole timeline: first benched version to last, per pass.
overall = %i[no_yjit yjit].filter_map do |pass|
  current = ips_of.call(last_version, pass)
  reference = ips_of.call(first_version, pass)
  next unless current && reference && last_version != first_version

  "**#{percent.call(current, reference)}** #{pass == :yjit ? 'with' : 'without'} YJIT"
end

File.open(report_path, 'w') do |f|
  row = ->(cells) { f.puts("| #{cells.join(' | ')} |") }

  f.puts "# Grape throughput by version\n\n"
  f.puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')}  "
  f.puts "Ruby: #{ruby_desc}  "
  f.puts "Host: #{host_desc}  "
  f.puts "YJIT available: #{with_yjit}\n\n"
  f.puts 'Single-threaded `Benchmark.ips`, 2s warmup + 5s measure, ' \
         '`BenchAPI.call(env)` against `/api/v1/hello` returning a small JSON object. ' \
         "Reproduce with `ruby benchmark/version_throughput/run.rb`.\n\n"

  row.call(headers)
  row.call(['---'] + Array.new(headers.size - 1, '---:'))
  versions.each { |version| row.call(row_for.call(version)) }

  f.puts "\nOver time, #{first_version} → #{last_version}: #{overall.join(', ')}." unless overall.empty?

  f.puts "\n## Notes"
  f.puts '- All versions exercised through the same `BenchAPI` definition (kept stable in `app.rb`).'
  f.puts "- `vs prev` compares throughput against the previous benched version and `vs #{first_version}` " \
         'against the first one; read those columns for improvement over time.'
  f.puts '- Results are noisy at this scale (±5-8%); rerun if a number looks off.'
  if with_yjit
    f.puts '- `YJIT speedup` is `(yjit_ips - no_yjit_ips) / no_yjit_ips`.'
    f.puts '- YJIT pass uses `ruby --yjit`; both passes share the same Ruby binary.'
  end
end

puts "\nWritten: #{report_path}"
