module Grape
  module Http
    module Headers
      # https://github.com/rack/rack/blob/master/lib/rack.rb
      HTTP_VERSION    = 'HTTP_VERSION'.freeze
      PATH_INFO       = 'PATH_INFO'.freeze
      QUERY_STRING    = 'QUERY_STRING'.freeze
      CONTENT_TYPE    = 'Content-Type'.freeze

      GET     = 'GET'.freeze
      POST    = 'POST'.freeze
      PUT     = 'PUT'.freeze
      PATCH   = 'PATCH'.freeze
      DELETE  = 'DELETE'.freeze
      HEAD    = 'HEAD'.freeze
      OPTIONS = 'OPTIONS'.freeze

      HTTP_ACCEPT_VERSION    = 'HTTP_ACCEPT_VERSION'.freeze
      X_CASCADE              = 'X-Cascade'.freeze
      HTTP_TRANSFER_ENCODING = 'HTTP_TRANSFER_ENCODING'.freeze
      HTTP_ACCEPT            = 'HTTP_ACCEPT'.freeze

      FORMAT                 = 'format'.freeze
    end
  end
end
