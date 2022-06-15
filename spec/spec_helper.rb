# frozen_string_literal: true

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'support'))

require 'grape'
require 'test_prof/recipes/rspec/let_it_be'

class NullAdapter
  def begin_transaction; end

  def rollback_transaction; end
end

TestProf::BeforeAll.adapter = NullAdapter.new

require 'rubygems'
require 'bundler'
Bundler.require :default, :test

Dir["#{File.dirname(__FILE__)}/support/*.rb"].sort.each do |file|
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
  config.warnings = true

  config.before(:all) { Grape::Util::InheritableSetting.reset_global! }
  config.before { Grape::Util::InheritableSetting.reset_global! }

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
end

require 'simplecov'
require 'simplecov-lcov'
SimpleCov::Formatter::LcovFormatter.config do |c|
  c.report_with_single_file = true
  c.single_report_path = 'coverage/lcov.info'
end

SimpleCov.formatter = SimpleCov::Formatter::LcovFormatter
SimpleCov.start
