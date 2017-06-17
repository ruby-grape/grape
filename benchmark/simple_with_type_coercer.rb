$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'grape'
require 'benchmark/ips'

api = Class.new(Grape::API) do
  prefix :api
  version 'v1', using: :path
  params do
    requires :param, type: Array[String]
  end
  get '/' do
    'hello'
  end
end

env = Rack::MockRequest.env_for('/api/v1?param=value', method: 'GET')

Benchmark.ips do |ips|
  ips.report('simple_with_type_coercer') do
    api.call(env)
  end
end
