# frozen_string_literal: true

module Grape
  module Http
    module Headers
      # https://github.com/rack/rack/blob/master/lib/rack.rb
      HTTP_VERSION    = 'HTTP_VERSION'
      PATH_INFO       = 'PATH_INFO'
      REQUEST_METHOD  = 'REQUEST_METHOD'
      QUERY_STRING    = 'QUERY_STRING'
      CONTENT_TYPE    = 'Content-Type'

      GET     = 'GET'
      POST    = 'POST'
      PUT     = 'PUT'
      PATCH   = 'PATCH'
      DELETE  = 'DELETE'
      HEAD    = 'HEAD'
      OPTIONS = 'OPTIONS'

      SUPPORTED_METHODS = [GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS].freeze

      HTTP_ACCEPT_VERSION    = 'HTTP_ACCEPT_VERSION'
      X_CASCADE              = 'X-Cascade'
      HTTP_TRANSFER_ENCODING = 'HTTP_TRANSFER_ENCODING'
      HTTP_ACCEPT            = 'HTTP_ACCEPT'

      FORMAT                 = 'format'

      def self.find_supported_method(route_method)
        Grape::Http::Headers::SUPPORTED_METHODS.detect { |supported_method| supported_method.casecmp(route_method).zero? }
      end
    end
  end
end
