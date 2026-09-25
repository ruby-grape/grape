#!/usr/bin/env ruby
# frozen_string_literal: true

# API Profiling Script
#
# This script makes parallel API calls to various endpoints using a thread pool.
# It's designed to generate load for memory profiling.
#
# Usage (see README.md for profiling the server under ruby-memory-profiler):
#   # Basic usage (assumes server running on localhost:9292)
#   ruby profile_api_calls.rb
#
#   # With custom configuration via environment variables
#   API_BASE_URL=http://localhost:9292 THREAD_POOL_SIZE=20 TOTAL_ITERATIONS=10 ruby profile_api_calls.rb
#
# Environment Variables:
#   API_BASE_URL - Base URL for the API (default: http://localhost:9292)
#   THREAD_POOL_SIZE - Number of threads in the pool (default: 10)
#   CALLS_PER_ENDPOINT - Printed in the header only; every test case runs once per iteration (default: 50)
#   TOTAL_ITERATIONS - Total number of iterations (default: 100)

require 'net/http'
require 'uri'
require 'json'

# Configuration
BASE_URL = ENV['API_BASE_URL'] || 'http://localhost:9292'
THREAD_POOL_SIZE = ENV['THREAD_POOL_SIZE']&.to_i || 10
CALLS_PER_ENDPOINT = ENV['CALLS_PER_ENDPOINT']&.to_i || 50
TOTAL_ITERATIONS = ENV['TOTAL_ITERATIONS']&.to_i || 100

# Thread pool implementation
class ThreadPool
  def initialize(size)
    @size = size
    @queue = Queue.new
    @threads = []
    @pending = 0
    @pending_mutex = Mutex.new
    @size.times do
      @threads << Thread.new do
        loop do
          task = @queue.pop
          break if task == :shutdown

          @pending_mutex.synchronize { @pending += 1 }
          begin
            task.call
          ensure
            @pending_mutex.synchronize { @pending -= 1 }
          end
        end
      end
    end
  end

  def submit(&block)
    @queue << block
  end

  def pending_count
    @pending_mutex.synchronize { @pending }
  end

  def queue_size
    @queue.size
  end

  def all_done?
    queue_size.zero? && pending_count.zero?
  end

  def shutdown
    @size.times { @queue << :shutdown }
    @threads.each(&:join)
  end
end

# HTTP client wrapper
class APIClient
  def initialize(base_url)
    @base_url = base_url
  end

  def get(path, headers = {})
    make_request(:get, path, nil, headers)
  end

  def post(path, body = nil, headers = {})
    make_request(:post, path, body, headers)
  end

  def put(path, body = nil, headers = {})
    make_request(:put, path, body, headers)
  end

  private

  def make_request(method, path, body = nil, headers = {})
    # Handle paths that might include query strings
    full_uri = URI.join(@base_url, path)

    http = Net::HTTP.new(full_uri.host, full_uri.port)
    http.read_timeout = 30
    http.open_timeout = 10

    request = case method
              when :get
                Net::HTTP::Get.new(full_uri.request_uri)
              when :post
                Net::HTTP::Post.new(full_uri.request_uri)
              when :put
                Net::HTTP::Put.new(full_uri.request_uri)
              end

    headers.each { |k, v| request[k] = v }
    request['Content-Type'] = 'application/json' if body && !headers['Content-Type']
    request.body = body.to_json if body

    response = http.request(request)
    {
      status: response.code.to_i,
      body: response.body,
      headers: response.to_hash
    }
  rescue StandardError => e
    {
      status: 0,
      error: e.message,
      body: nil
    }
  end
end

# API endpoint definitions with various test cases
class APITestCases
  def initialize(client)
    @client = client
  end

  def ping_tests
    [
      -> { @client.get('/api/ping') }
    ]
  end

  def post_json_tests
    [
      -> { @client.post('/api/spline', { reticulated: 'simple' }) },
      -> { @client.post('/api/spline', { reticulated: 'complex' }) },
      -> { @client.post('/api/spline', { reticulated: 'very long string ' * 100 }) },
      -> { @client.post('/api/spline', { reticulated: 'unicode: 测试 🚀 émojis' }) },
      -> { @client.post('/api/spline', { reticulated: '{"nested": "json"}' }) }
    ]
  end

  def _get_json_tests
    test_cases = []
    # Various spline configurations
    [
      [{ id: 1, reticulated: true }],
      [{ id: 1, reticulated: false }, { id: 2, reticulated: true }],
      Array.new(10) { |i| { id: i + 1, reticulated: i.even? } },
      Array.new(50) { |i| { id: i + 1, reticulated: i.odd? } },
      Array.new(100) { |i| { id: i + 1, reticulated: (i % 3).zero? } }
    ].each do |splines|
      # Capture splines in closure properly
      splines_data = splines
      test_cases << lambda do
        path = '/api/reticulated_splines'
        query = URI.encode_www_form(splines: splines_data.to_json)
        @client.get("#{path}?#{query}")
      end
    end
    test_cases
  end

  def post_put_tests
    [
      -> { @client.get('/api/ring') },
      -> { @client.post('/api/ring') },
      -> { @client.put('/api/ring', { count: 1 }) },
      -> { @client.put('/api/ring', { count: 5 }) },
      -> { @client.put('/api/ring', { count: 100 }) },
      -> { @client.put('/api/ring', { count: -10 }) }
    ]
  end

  def headers_tests
    test_cases = []
    # Test various header keys - fix closure bug by capturing key in local variable
    %w[Content-Type Accept Authorization User-Agent X-Custom-Header].each do |key|
      captured_key = key # Capture in local variable to avoid closure bug
      test_cases << lambda do
        @client.get("/api/headers/#{captured_key}", { captured_key => "test-value-#{rand(1000)}" })
      end
    end
    test_cases << -> { @client.get('/api/headers') }
    test_cases
  end

  def entities_tests
    test_cases = []
    # Test various entity IDs and formats - fix closure bug
    (1..10).each do |id|
      captured_id = id # Capture in local variable to avoid closure bug
      test_cases << -> { @client.get("/api/entities/#{captured_id}") }
      test_cases << -> { @client.get("/api/entities/#{captured_id}?foo=bar") }
      test_cases << -> { @client.get("/api/entities/#{captured_id}", { 'Accept' => 'application/xml' }) }
    end
    test_cases
  end

  def path_versioning_tests
    [
      -> { @client.get('/api/vendor/acme') },
      -> { @client.get('/api/vendor/acme.json') }
    ]
  end

  def header_versioning_tests
    # Header versioning endpoint is mounted, so it should be accessible at /api with version header
    # But since it's a mounted API with versioning, we need to check the actual route
    # For now, let's try the root path with the version header
    [
      -> { @client.get('/', { 'Accept' => 'application/vnd.acme-v1+json' }) },
      -> { @client.get('/', { 'Accept' => 'application/vnd.acme-v1+json; charset=utf-8' }) }
    ]
  end

  def content_type_tests
    [
      -> { @client.get('/api/plain_text') },
      -> { @client.get('/api/mixed') },
      -> { @client.get('/api/mixed.json') },
      -> { @client.get('/api/mixed.xml', { 'Accept' => 'application/xml' }) }
    ]
  end

  def stream_data_tests
    [
      -> { @client.get('/api/stream') }
    ]
  end

  def rescue_from_tests
    [
      -> { @client.get('/api/raise') }
    ]
  end

  def wrap_response_tests
    [
      -> { @client.get('/api/decorated/ping') }
    ]
  end

  def all_tests
    [
      ping_tests,
      post_json_tests,
      _get_json_tests,
      post_put_tests,
      headers_tests,
      entities_tests,
      path_versioning_tests,
      header_versioning_tests,
      content_type_tests,
      stream_data_tests,
      rescue_from_tests,
      wrap_response_tests
    ].flatten
  end
end

# Main execution
def main
  puts 'Starting API profiling script'
  puts "Base URL: #{BASE_URL}"
  puts "Thread pool size: #{THREAD_POOL_SIZE}"
  puts "Calls per endpoint: #{CALLS_PER_ENDPOINT}"
  puts "Total iterations: #{TOTAL_ITERATIONS}"
  puts '-' * 60

  client = APIClient.new(BASE_URL)
  test_cases = APITestCases.new(client)
  all_tests = test_cases.all_tests

  puts "Total test cases: #{all_tests.length}"
  puts 'Starting parallel execution...'
  puts '-' * 60

  pool = ThreadPool.new(THREAD_POOL_SIZE)
  results = { success: 0, errors: 0, total: 0, status_counts: Hash.new(0) }
  results_mutex = Mutex.new

  start_time = Time.now

  # Submit tasks to thread pool
  TOTAL_ITERATIONS.times do
    all_tests.each do |test_case|
      pool.submit do
        response = test_case.call
        results_mutex.synchronize do
          results[:total] += 1
          status = response[:status]
          results[:status_counts][status] = (results[:status_counts][status] || 0) + 1

          if status >= 200 && status < 400
            results[:success] += 1
          else
            results[:errors] += 1
            # Only print first few errors to avoid spam
            if results[:errors] <= 10
              error_msg = response[:error] || response[:body]&.slice(0, 150)
              puts "\nError #{status}: #{error_msg}"
            end
          end
          print '.' if (results[:total] % 100).zero?
          $stdout.flush
        end
      rescue StandardError => e
        results_mutex.synchronize do
          results[:errors] += 1
          puts "\nException: #{e.class}: #{e.message}" if results[:errors] <= 10
        end
      end
    end
  end

  # Wait for all tasks to complete
  sleep(0.1) until pool.all_done?

  pool.shutdown

  end_time = Time.now
  duration = end_time - start_time

  puts "\n#{'=' * 60}"
  puts 'Profiling complete!'
  puts '=' * 60
  puts "Total requests: #{results[:total]}"
  puts "Successful: #{results[:success]}"
  puts "Errors: #{results[:errors]}"
  puts "Duration: #{duration.round(2)} seconds"
  rps = (results[:total] / duration.to_f).round(2)
  puts "Requests per second: #{rps}"
  puts "\nStatus code breakdown:"
  results[:status_counts].sort.each do |status, count|
    puts "  #{status}: #{count}"
  end
  puts '=' * 60
end

# Run if executed directly
main if __FILE__ == $PROGRAM_NAME
