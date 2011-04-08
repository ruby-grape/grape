require 'rack'
require 'rack/builder'

module Grape
  autoload :API, 'grape/api'
  autoload :Endpoint, 'grape/endpoint'
  autoload :MiddlewareStack, 'grape/middleware_stack'
  autoload :Client, 'grape/client'
  
  module Middleware
    autoload :Base,      'grape/middleware/base'
    autoload :Prefixer,  'grape/middleware/prefixer'
    autoload :Versioner, 'grape/middleware/versioner'
    autoload :Formatter, 'grape/middleware/formatter'
    autoload :Error,     'grape/middleware/error'
    
    module Auth
      autoload :OAuth2, 'grape/middleware/auth/oauth2'
      autoload :Basic,  'grape/middleware/auth/basic'
    end
  end
end

require 'grape/version'
