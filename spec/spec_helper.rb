$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support'))

require 'grape'

require 'rubygems'
require 'bundler'
Bundler.setup :default, :test

require 'json'
require 'rack/test'
require 'base64'
require 'cookiejar'
require 'json'
require 'mime/types'
require 'pry'

Dir["#{File.dirname(__FILE__)}/support/*.rb"].each do |file|
  require file
end

I18n.enforce_available_locales = false

RSpec.configure do |config|
  config.include Rack::Test::Methods

  # Have guard-spork run only the tests marked with focus: true
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.filter_run focus: true unless ENV['FORBID_FOCUSED_SPECS']
  config.run_all_when_everything_filtered = true
end


