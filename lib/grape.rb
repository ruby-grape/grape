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
  autoload :API,                 'grape/api'
  autoload :Endpoint,            'grape/endpoint'

  autoload :Route,               'grape/route'
  autoload :Namespace,           'grape/namespace'

  autoload :Path,                'grape/path'

  autoload :Cookies,             'grape/cookies'
  autoload :Validations,         'grape/validations'
  autoload :Request,             'grape/http/request'

  module Exceptions
    autoload :Base,                           'grape/exceptions/base'
    autoload :Validation,                     'grape/exceptions/validation'
    autoload :ValidationErrors,               'grape/exceptions/validation_errors'
    autoload :MissingVendorOption,            'grape/exceptions/missing_vendor_option'
    autoload :MissingMimeType,                'grape/exceptions/missing_mime_type'
    autoload :MissingOption,                  'grape/exceptions/missing_option'
    autoload :InvalidFormatter,               'grape/exceptions/invalid_formatter'
    autoload :InvalidVersionerOption,         'grape/exceptions/invalid_versioner_option'
    autoload :UnknownValidator,               'grape/exceptions/unknown_validator'
    autoload :UnknownOptions,                 'grape/exceptions/unknown_options'
    autoload :InvalidWithOptionForRepresent,  'grape/exceptions/invalid_with_option_for_represent'
    autoload :IncompatibleOptionValues,       'grape/exceptions/incompatible_option_values'
    autoload :MissingGroupTypeError,          'grape/exceptions/missing_group_type'
    autoload :UnsupportedGroupTypeError,      'grape/exceptions/unsupported_group_type'
    autoload :InvalidMessageBody,             'grape/exceptions/invalid_message_body'
    autoload :InvalidAcceptHeader,            'grape/exceptions/invalid_accept_header'
  end

  module ErrorFormatter
    autoload :Base,              'grape/error_formatter/base'
    autoload :Json,              'grape/error_formatter/json'
    autoload :Txt,               'grape/error_formatter/txt'
    autoload :Xml,               'grape/error_formatter/xml'
  end

  module Formatter
    autoload :Base,              'grape/formatter/base'
    autoload :Json,              'grape/formatter/json'
    autoload :SerializableHash,  'grape/formatter/serializable_hash'
    autoload :Txt,               'grape/formatter/txt'
    autoload :Xml,               'grape/formatter/xml'
  end

  module Parser
    autoload :Base,              'grape/parser/base'
    autoload :Json,              'grape/parser/json'
    autoload :Xml,               'grape/parser/xml'
  end

  module Middleware
    autoload :Base,              'grape/middleware/base'
    autoload :Versioner,         'grape/middleware/versioner'
    autoload :Formatter,         'grape/middleware/formatter'
    autoload :Error,             'grape/middleware/error'

    module Auth
      autoload :Base,            'grape/middleware/auth/base'
      autoload :DSL,             'grape/middleware/auth/dsl'
      autoload :StrategyInfo,    'grape/middleware/auth/strategy_info'
      autoload :Strategies,      'grape/middleware/auth/strategies'
    end

    module Versioner
      autoload :Path,                 'grape/middleware/versioner/path'
      autoload :Header,               'grape/middleware/versioner/header'
      autoload :Param,                'grape/middleware/versioner/param'
      autoload :AcceptVersionHeader,  'grape/middleware/versioner/accept_version_header'
    end
  end

  module Util
    autoload :InheritableValues, 'grape/util/inheritable_values'
    autoload :StackableValues,   'grape/util/stackable_values'
    autoload :InheritableSetting, 'grape/util/inheritable_setting'
    autoload :StrictHashConfiguration, 'grape/util/strict_hash_configuration'
  end

  module DSL
    autoload :API,               'grape/dsl/api'
    autoload :Callbacks,         'grape/dsl/callbacks'
    autoload :Settings,          'grape/dsl/settings'
    autoload :Configuration,     'grape/dsl/configuration'
    autoload :InsideRoute,       'grape/dsl/inside_route'
    autoload :Helpers,           'grape/dsl/helpers'
    autoload :Middleware,        'grape/dsl/middleware'
    autoload :Parameters,        'grape/dsl/parameters'
    autoload :RequestResponse,   'grape/dsl/request_response'
    autoload :Routing,           'grape/dsl/routing'
    autoload :Validations,       'grape/dsl/validations'
  end

  class API
    autoload :Helpers,           'grape/api/helpers'
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
