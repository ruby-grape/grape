require 'logger'
require 'rack'
require 'rack/mount'
require 'rack/builder'
require 'rack/accept'
require 'rack/auth/basic'
require 'rack/auth/digest/md5'
require 'hashie'
require 'active_support/all'
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
  autoload :Cookies,             'grape/cookies'
  autoload :Validations,         'grape/validations'

  module Exceptions
    autoload :Base,                           'grape/exceptions/base'
    autoload :Validation,                     'grape/exceptions/validation'
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
      autoload :Basic,          'grape/middleware/auth/basic'
      autoload :Digest,	        'grape/middleware/auth/digest'
    end

    module Versioner
      autoload :Path,           'grape/middleware/versioner/path'
      autoload :Header,         'grape/middleware/versioner/header'
      autoload :Param,          'grape/middleware/versioner/param'
    end
  end

  module Util
    autoload :HashStack,         'grape/util/hash_stack'
  end
end

require 'grape/version'
