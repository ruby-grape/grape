# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'grape'
require 'benchmark/ips'
require 'memory_profiler'

class API < Grape::API
  prefix :api
  version 'v1', using: :path

  2000.times do |index|
    get "/test#{index}/" do
      'hello'
    end
  end
end

MemoryProfiler.report(allow_files: 'grape') do
  API.compile!
end.pretty_print(to_file: 'optimize_path.txt')
