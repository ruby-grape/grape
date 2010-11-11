$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'grape'

require 'rubygems'
require 'bundler'
Bundler.setup :default, :test

require 'rspec'
require 'rack/test'

require 'base64'
def encode_basic(username, password)
  "Basic " + Base64.encode64("#{username}:#{password}")
end

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
