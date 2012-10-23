require 'rack'
require 'rack/builder'

module Grape
  autoload :API,             'grape/api'
  autoload :Endpoint,        'grape/endpoint'
  autoload :MiddlewareStack, 'grape/middleware_stack'
  autoload :Client,          'grape/client'
  autoload :Route,           'grape/route'
  autoload :Entity,          'grape/entity'
  autoload :Cookies,         'grape/cookies'
  autoload :Validations,     'grape/validations'

  module Exceptions
    autoload :Base, 'grape/exceptions/base'
    autoload :ValidationError, 'grape/exceptions/validation_error'
  end

  module Middleware
    autoload :Base,      'grape/middleware/base'
    autoload :Prefixer,  'grape/middleware/prefixer'
    autoload :Versioner, 'grape/middleware/versioner'
    autoload :Formatter, 'grape/middleware/formatter'
    autoload :Error,     'grape/middleware/error'

    module Auth
      autoload :OAuth2, 'grape/middleware/auth/oauth2'
      autoload :Basic,  'grape/middleware/auth/basic'
      autoload :Digest,	'grape/middleware/auth/digest'
    end

    module Versioner
      autoload :Path,   'grape/middleware/versioner/path'
      autoload :Header, 'grape/middleware/versioner/header'
      autoload :Param,  'grape/middleware/versioner/param'
    end
  end

  module Util
    autoload :HashStack, 'grape/util/hash_stack'
  end
end

require 'grape/version'
