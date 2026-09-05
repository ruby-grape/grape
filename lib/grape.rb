# frozen_string_literal: true

require 'logger'
require 'monitor'
require 'active_support'
require 'active_support/isolated_execution_state'
require 'active_support/core_ext/array/conversions' # to_xml
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/hash/conversions' # to_xml
require 'active_support/core_ext/hash/deep_merge'
require 'active_support/core_ext/hash/deep_transform_values'
require 'active_support/core_ext/hash/indifferent_access' # nested_under_indifferent_access, required by HashWithIndifferentAccess.new
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext/module/delegation' # delegate_missing_to
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/deep_dup'
require 'active_support/core_ext/object/duplicable'
require 'active_support/core_ext/string/inflections' # demodulize, underscore
require 'active_support/deprecation'
require 'active_support/ordered_options'
require 'active_support/notifications'

require 'English'
require 'bigdecimal'
require 'date'
require 'dry-types'
require 'dry-configurable'
require 'forwardable'
require 'json'
require 'mustermann'
require 'mustermann/ast/pattern'
require 'rack'
require 'rack/auth/basic'
require 'rack/builder'
require 'rack/head'
require 'singleton'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'api' => 'API',
  'dsl' => 'DSL'
)
railtie = "#{__dir__}/grape/railtie.rb"
# Grape::Testing is a test-environment helper -- it extends Grape::Endpoint with
# `before_each` and prepends a hook to Grape::Endpoint#run. It is documented as
# opt-in (`require 'grape/testing'`), which eager loading quietly contradicted
# by installing it in every process.
testing = "#{__dir__}/grape/testing.rb"
loader.do_not_eager_load(railtie, testing)
loader.setup

I18n.load_path << File.expand_path('grape/locale/en.yml', __dir__)

module Grape
  extend Dry::Configurable

  setting :param_builder, default: :hash_with_indifferent_access
  setting :lint, default: false
  setting :warn_on_helper_overrides, default: false
  # Let an error response that cannot be rendered propagate out of the
  # middleware stack instead of being answered with a failsafe 500.
  setting :raise_rendering_errors, default: false

  # The HTTP QUERY method (RFC 10008): a safe, idempotent request whose content
  # carries the query. Rack has no constant for it yet, hence the literal.
  QUERY = 'QUERY'

  HTTP_SUPPORTED_METHODS = [
    Rack::GET,
    QUERY,
    Rack::POST,
    Rack::PUT,
    Rack::PATCH,
    Rack::DELETE,
    Rack::HEAD,
    Rack::OPTIONS
  ].freeze

  # Rack errors that should be rescued and wrapped as Grape::Exceptions::RequestError.
  # Rack 3.1.0 introduced Rack::BadRequest as a marker module included by all bad request
  # exception classes, allowing a single rescue entry to cover them all.
  # Before, these errors are raised as individual exception classes.
  RACK_ERRORS =
    if Gem::Version.new(Rack.release) >= Gem::Version.new('3.1.0')
      [EOFError, Rack::BadRequest]
    else
      [
        EOFError,
        Rack::Multipart::MultipartPartLimitError,
        Rack::Multipart::MultipartTotalPartLimitError,
        Rack::Utils::ParameterTypeError,
        Rack::Utils::InvalidParameterError,
        Rack::QueryParser::ParamsTooDeepError
      ]
    end.freeze

  # The deprecation horizon is the version a deprecation announces as its
  # removal point, so it is the *next* major rather than the current one, and
  # it is derived from VERSION rather than written out. Written out, it went
  # stale: it said '2.0' from 2023 (#2353) through all of 2.x, 3.x and 4.x, so
  # a method deprecated through this deprecator announced a removal version
  # that had already shipped, and every custom `behavior` lambda -- how a Rails
  # app consumes deprecations -- was handed the same wrong number.
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new("#{Gem::Version.new(VERSION).segments.first + 1}.0", 'Grape')
  end
end

# https://api.rubyonrails.org/classes/ActiveSupport/Deprecation.html
# adding Grape.deprecator to Rails App if any
require 'grape/railtie' if defined?(Rails::Railtie)
loader.eager_load
