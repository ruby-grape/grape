# frozen_string_literal: true

require 'logger'
require 'active_support'
require 'active_support/version'
require 'active_support/isolated_execution_state'
require 'active_support/core_ext/array/conversions' # to_xml
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/hash/conversions' # to_xml
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/deep_transform_values'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/hash/reverse_merge'
require 'active_support/core_ext/module/delegation' # delegate_missing_to
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/object/duplicable'
require 'active_support/deprecation'
require 'active_support/inflector'
require 'active_support/ordered_options'
require 'active_support/notifications'

require 'English'
require 'bigdecimal'
require 'date'
require 'dry-types'
require 'dry-configurable'
require 'forwardable'
require 'json'
require 'mustermann/grape'
require 'pathname'
require 'rack'
require 'rack/auth/basic'
require 'rack/builder'
require 'rack/head'
require 'set'
require 'singleton'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'api' => 'API',
  'dsl' => 'DSL'
)
railtie = "#{__dir__}/grape/railtie.rb"
loader.do_not_eager_load(railtie)
loader.setup

I18n.load_path << File.expand_path('grape/locale/en.yml', __dir__)

module Grape
  extend Dry::Configurable

  setting :param_builder, default: :hash_with_indifferent_access
  setting :lint, default: false

  HTTP_SUPPORTED_METHODS = [
    Rack::GET,
    Rack::POST,
    Rack::PUT,
    Rack::PATCH,
    Rack::DELETE,
    Rack::HEAD,
    Rack::OPTIONS
  ].freeze

  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new('2.0', 'Grape')
  end
end

# https://api.rubyonrails.org/classes/ActiveSupport/Deprecation.html
# adding Grape.deprecator to Rails App if any
require 'grape/railtie' if defined?(Rails::Railtie)
loader.eager_load
