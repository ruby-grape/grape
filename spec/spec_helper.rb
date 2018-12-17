$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support'))

require 'grape'

require 'rubygems'
require 'bundler'
Bundler.require :default, :test

Dir["#{File.dirname(__FILE__)}/support/*.rb"].each do |file|
  require file
end

# The default value for this setting is true in a standard Rails app,
# so it should be set to true here as well to reflect that.
I18n.enforce_available_locales = true

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Spec::Support::Helpers
  config.raise_errors_for_deprecations!
  config.filter_run_when_matching :focus

  config.before(:each) { Grape::Util::InheritableSetting.reset_global! }
end

require 'coveralls'
Coveralls.wear!
