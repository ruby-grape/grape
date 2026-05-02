# frozen_string_literal: true

# Version-agnostic Grape API used by version_throughput benchmark.
# Kept tiny and using only DSL surface that's been stable across Grape 3.x —
# so the same script can be exec'd against 3.0.0 ... master without changes.
require 'grape'

class BenchAPI < Grape::API
  prefix :api
  format :json
  version 'v1', using: :path

  get '/hello' do
    { hello: 'world' }
  end
end
