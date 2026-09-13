# frozen_string_literal: true

# Version-agnostic Grape APIs used by version_throughput benchmark. Kept tiny
# and using only DSL surface that's been stable across Grape 3.x, so the same
# script can be exec'd against 3.0.1 ... master without changes.
require 'grape'

class StaticRouteBenchAPI < Grape::API
  prefix :api
  format :json
  version 'v1', using: :path

  get '/hello' do
    { hello: 'world' }
  end
end

class ParameterizedRouteBenchAPI < Grape::API
  prefix :api
  format :json
  version 'v1', using: :path

  get '/hello/:id' do
    { hello: 'world' }
  end
end

class ManyStaticRoutesBenchAPI < Grape::API
  ROUTE_COUNT = 200

  prefix :api
  format :json
  version 'v1', using: :path

  ROUTE_COUNT.times do |index|
    get "/resource#{index}" do
      { hello: 'world' }
    end
  end
end

class ManyParameterizedRoutesBenchAPI < Grape::API
  ROUTE_COUNT = 200

  prefix :api
  format :json
  version 'v1', using: :path

  ROUTE_COUNT.times do |index|
    get "/resource#{index}/:id" do
      { hello: 'world' }
    end
  end
end
