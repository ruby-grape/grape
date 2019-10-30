require 'grape'
require 'benchmark/ips'

class API < Grape::API
  prefix :api
  version 'v1', using: :path

  params do
    requires :address, type: Hash do
      requires :street, type: String
      requires :postal_code, type: Integer
      optional :city, type: String
    end
  end
  post '/' do
    'hello'
  end
end

options = {
  method: 'POST',
  params: {
    address: {
      street: 'Alexis Pl.',
      postal_code: '90210',
      city: 'Beverly Hills'
    }
  }
}

env = Rack::MockRequest.env_for('/api/v1', options)

10.times do |i|
  env["HTTP_HEADER#{i}"] = '123'
end

Benchmark.ips do |ips|
  ips.report('POST with nested params') do
    API.call env
  end
end
