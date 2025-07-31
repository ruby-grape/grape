# frozen_string_literal: true

require 'bundler/inline'

gemfile(true) do
  source 'https://rubygems.org'
  gem 'grape'
  gem 'rack'
  gem 'minitest'
  gem 'rack-test'
end

require 'minitest/autorun'
require 'rack/test'
require 'grape'

class GrapeAPIBugTest < Minitest::Test
  include Rack::Test::Methods

  RootAPI = Class.new(Grape::API) do
    format :json

    delete :test do
      status 200
      []
    end
  end

  def test_v1_users_via_api
    env = Rack::MockRequest.env_for('/test', method: Rack::DELETE)
    response = Rack::MockResponse[*RootAPI.call(env)]

    assert_equal '[]', response.body
    assert_equal 200, response.status
  end
end
