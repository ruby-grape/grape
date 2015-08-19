$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'grape'
require 'benchmark'

class API < Grape::API
  prefix :api
  version 'v1', using: :path
  get '/' do
    'hello'
  end
end

options = {
  method: 'GET'
}

env = Rack::MockRequest.env_for('/api/v1', options)

10.times do |i|
  env["HTTP_HEADER#{i}"] = '123'
end

iters = 5000

Benchmark.bm do |bm|
  bm.report('simple') do
    iters.times do
      API.call env
    end
  end
end
