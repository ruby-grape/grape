# frozen_string_literal: true

require 'simplecov'
require 'rubygems'
require 'bundler'
Bundler.require :default, :test

Grape.deprecator.behavior = :raise

%w[config support].each do |dir|
  Dir["#{File.dirname(__FILE__)}/#{dir}/**/*.rb"].sort.each do |file|
    require file
  end
end

Grape.config.lint = true # lint all apis by default
Grape::Util::Registry.include(Deregister)
# issue with ruby 2.7 with ^. We need to extend it again
Grape::Validations.extend(Grape::Util::Registry) if Gem::Version.new(RUBY_VERSION).release < Gem::Version.new('3.0')

# The default value for this setting is true in a standard Rails app,
# so it should be set to true here as well to reflect that.
I18n.enforce_available_locales = true

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include Spec::Support::Helpers
  config.raise_errors_for_deprecations!
  config.filter_run_when_matching :focus

  config.before(:all) { Grape::Util::InheritableSetting.reset_global! }
  config.before { Grape::Util::InheritableSetting.reset_global! }

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
end
