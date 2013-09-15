require 'logger'
require 'rack'
require 'rack/mount'
require 'rack/builder'
require 'rack/accept'
require 'rack/auth/basic'
require 'rack/auth/digest/md5'
require 'hashie'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/ordered_hash'
require 'active_support/core_ext/object/conversions'
require 'active_support/core_ext/array/extract_options'
require 'grape/util/deep_merge'
require 'grape/util/content_types'
require 'multi_json'
require 'multi_xml'
require 'virtus'
require 'i18n'

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
      autoload :OAuth2,         'grape/middleware/auth/oauth2'
      autoload :Base,	          'grape/middleware/auth/base'
      autoload :Basic,          'grape/middleware/auth/basic'
      autoload :Digest,	        'grape/middleware/auth/digest'
    end

    module Versioner
      autoload :Path,                 'grape/middleware/versioner/path'
      autoload :Header,               'grape/middleware/versioner/header'
      autoload :Param,                'grape/middleware/versioner/param'
      autoload :AcceptVersionHeader,  'grape/middleware/versioner/accept_version_header'
    end
  end

  module Util
    autoload :HashStack,         'grape/util/hash_stack'
  end
end

require 'grape/version'
