# frozen_string_literal: true

# Orchestrator: runs benchmark/version_throughput/bench.rb against each
# Grape version listed below in a clean subprocess (one bundle per version
# under tmp/), parses the RESULT line, and writes a Markdown table to
# benchmark/version_throughput/RESULTS.md.
#
# Each version is benched twice: once without YJIT, once with `--yjit`
# (skipped if the running Ruby wasn't built with YJIT). Results show both
# columns plus the YJIT speedup.
#
# Usage:
#   ruby benchmark/version_throughput/run.rb
#
# To bench against a specific subset:
#   GRAPE_VERSIONS="3.0.0,3.2.1,master" ruby benchmark/version_throughput/run.rb
#
# To run a YJIT-enabled Ruby that isn't the project default:
#   RBENV_VERSION=4.0.3 ruby benchmark/version_throughput/run.rb

require 'fileutils'
require 'open3'
require 'rbconfig'

ROOT = File.expand_path('../..', __dir__)
HERE = __dir__
TMP  = File.join(ROOT, 'tmp', 'bench-versions')

DEFAULT_VERSIONS = %w[3.0.0 3.0.1 3.1.0 3.1.1 3.2.0 3.2.1 master].freeze
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

File.open(report_path, 'w') do |f|
  f.puts "# Grape throughput by version\n\n"
  f.puts "Generated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S %Z')}  "
  f.puts "Ruby: #{ruby_desc}  "
  f.puts "Host: #{host_desc}  "
  f.puts "YJIT available: #{with_yjit}\n\n"
  f.puts 'Single-threaded `Benchmark.ips`, 2s warmup + 5s measure, ' \
         '`BenchAPI.call(env)` against `/api/v1/hello` returning a small JSON object. ' \
         "Reproduce with `ruby benchmark/version_throughput/run.rb`.\n\n"

  if with_yjit
    f.puts '| Version | No-YJIT (i/s) | μs/req | YJIT (i/s) | μs/req | YJIT speedup |'
    f.puts '|---|---:|---:|---:|---:|---:|'
  else
    f.puts '| Version | Throughput (i/s) | μs/req | ± stddev |'
    f.puts '|---|---:|---:|---:|'
  end

  versions.each do |version|
    r = results[version]
    if r.is_a?(Hash) && r[:error]
      cols = with_yjit ? 5 : 3
      f.puts "| #{version} | error: #{r[:error]} #{'|' * cols}"
      next
    end

    no_yjit = r[:no_yjit]
    yjit = r[:yjit]

    if with_yjit
      no_yjit_cell = no_yjit&.dig(:ips) ? format_ips.call(no_yjit[:ips]) : 'err'
      no_yjit_us   = no_yjit&.dig(:us)  ? format('%.2f', no_yjit[:us]) : ''
      yjit_cell    = yjit&.dig(:ips)    ? format_ips.call(yjit[:ips]) : 'err'
      yjit_us      = yjit&.dig(:us)     ? format('%.2f', yjit[:us]) : ''
      speedup = (no_yjit&.dig(:ips) && yjit&.dig(:ips)) ?
        format('%+.1f%%', (yjit[:ips] - no_yjit[:ips]) / no_yjit[:ips] * 100.0) : '—'
      f.puts "| #{version} | #{no_yjit_cell} | #{no_yjit_us} | #{yjit_cell} | #{yjit_us} | #{speedup} |"
    else
      cell = no_yjit&.dig(:ips) ? format_ips.call(no_yjit[:ips]) : 'err'
      us = no_yjit&.dig(:us) ? format('%.2f', no_yjit[:us]) : ''
      stddev = no_yjit&.dig(:stddev) ? format('±%.2f%%', no_yjit[:stddev]) : ''
      f.puts "| #{version} | #{cell} | #{us} | #{stddev} |"
    end
  end

  f.puts "\n## Notes"
  f.puts '- All versions exercised through the same `BenchAPI` definition (kept stable in `app.rb`).'
  f.puts '- Results are noisy at this scale (±5-8%); rerun if a number looks off.'
  if with_yjit
    f.puts '- `YJIT speedup` is `(yjit_ips - no_yjit_ips) / no_yjit_ips`.'
    f.puts '- YJIT pass uses `ruby --yjit`; both passes share the same Ruby binary.'
  end
end

puts "\nWritten: #{report_path}"
