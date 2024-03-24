# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'grape'
require 'benchmark/ips'

class API < Grape::API
  prefix :api
  version 'v1', using: :path

  2000.times do |index|
    get "/test#{index}/" do
      'hello'
    end
  end
end

Benchmark.ips do |ips|
  ips.report('Compiling 2000 routes') do
    API.compile!
  end
end
