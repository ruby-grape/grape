require 'logger'
require 'rack'
require 'rack/mount'
require 'rack/builder'
require 'rack/accept'
require 'rack/auth/basic'
require 'rack/auth/digest/md5'
require 'hashie'
require 'set'
require 'active_support/version'
require 'active_support/core_ext/hash/indifferent_access'

if ActiveSupport::VERSION::MAJOR >= 4
  require 'active_support/core_ext/object/deep_dup'
else
  require_relative 'backports/active_support/deep_dup'
end

require 'active_support/ordered_hash'
require 'active_support/core_ext/object/conversions'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/hash/deep_merge'
require 'grape/util/content_types'
require 'multi_json'
require 'multi_xml'
require 'virtus'
require 'i18n'
require 'thread'

I18n.load_path << File.expand_path('../grape/locale/en.yml', __FILE__)

module Grape
  require 'grape/api'
  require 'grape/endpoint'

  require 'grape/route'
  require 'grape/namespace'

  require 'grape/path'

  require 'grape/cookies'
  require 'grape/validations'
  require 'grape/http/request'

  module Exceptions
    require 'grape/exceptions/base'
    require 'grape/exceptions/validation'
    require 'grape/exceptions/validation_errors'
    require 'grape/exceptions/missing_vendor_option'
    require 'grape/exceptions/missing_mime_type'
    require 'grape/exceptions/missing_option'
    require 'grape/exceptions/invalid_formatter'
    require 'grape/exceptions/invalid_versioner_option'
    require 'grape/exceptions/unknown_validator'
    require 'grape/exceptions/unknown_options'
    require 'grape/exceptions/invalid_with_option_for_represent'
    require 'grape/exceptions/incompatible_option_values'
    require 'grape/exceptions/missing_group_type'
    require 'grape/exceptions/unsupported_group_type'
    require 'grape/exceptions/invalid_message_body'
    require 'grape/exceptions/invalid_accept_header'
  end

  module ErrorFormatter
    require 'grape/error_formatter/base'
    require 'grape/error_formatter/json'
    require 'grape/error_formatter/txt'
    require 'grape/error_formatter/xml'
  end

  module Formatter
    require 'grape/formatter/base'
    require 'grape/formatter/json'
    require 'grape/formatter/serializable_hash'
    require 'grape/formatter/txt'
    require 'grape/formatter/xml'
  end

  module Parser
    require 'grape/parser/base'
    require 'grape/parser/json'
    require 'grape/parser/xml'
  end

  module Middleware
    require 'grape/middleware/base'
    require 'grape/middleware/versioner'
    require 'grape/middleware/formatter'
    require 'grape/middleware/error'

    module Auth
      require 'grape/middleware/auth/base'
      require 'grape/middleware/auth/dsl'
      require 'grape/middleware/auth/strategy_info'
      require 'grape/middleware/auth/strategies'
    end

    module Versioner
      require 'grape/middleware/versioner/path'
      require 'grape/middleware/versioner/header'
      require 'grape/middleware/versioner/param'
      require 'grape/middleware/versioner/accept_version_header'
    end
  end

  module Util
    require 'grape/util/inheritable_values'
    require 'grape/util/stackable_values'
    require 'grape/util/inheritable_setting'
    require 'grape/util/strict_hash_configuration'
  end

  module DSL
    require 'grape/dsl/api'
    require 'grape/dsl/callbacks'
    require 'grape/dsl/settings'
    require 'grape/dsl/configuration'
    require 'grape/dsl/inside_route'
    require 'grape/dsl/helpers'
    require 'grape/dsl/middleware'
    require 'grape/dsl/parameters'
    require 'grape/dsl/request_response'
    require 'grape/dsl/routing'
    require 'grape/dsl/validations'
  end

  class API
    require 'grape/api/helpers'
  end
end

require 'grape/validations/validators/base'
require 'grape/validations/attributes_iterator'
require 'grape/validations/validators/allow_blank'
require 'grape/validations/validators/at_least_one_of'
require 'grape/validations/validators/coerce'
require 'grape/validations/validators/default'
require 'grape/validations/validators/exactly_one_of'
require 'grape/validations/validators/mutual_exclusion'
require 'grape/validations/validators/presence'
require 'grape/validations/validators/regexp'
require 'grape/validations/validators/values'
require 'grape/validations/params_scope'
require 'grape/validations/validators/all_or_none'

require 'grape/version'
