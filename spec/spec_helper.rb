$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support'))

require 'grape'

require 'rubygems'
require 'bundler'
Bundler.setup :default, :test

require 'rack/test'
require 'pry'
require 'base64'
require 'cookiejar'
require 'json'

Dir["#{File.dirname(__FILE__)}/support/*.rb"].each do |file|
  require file
end

I18n.enforce_available_locales = false

RSpec.configure do |config|
  config.include Rack::Test::Methods
end
