# frozen_string_literal: true

require 'grape/util/lazy_object'

module Grape
  module Http
    module Headers
      # https://github.com/rack/rack/blob/master/lib/rack.rb
      HTTP_VERSION    = 'HTTP_VERSION'
      PATH_INFO       = 'PATH_INFO'
      REQUEST_METHOD  = 'REQUEST_METHOD'
      QUERY_STRING    = 'QUERY_STRING'

      if Gem::Version.new(Rack.release) < Gem::Version.new('3')
        ALLOW             = 'Allow'
        CACHE_CONTROL     = 'Cache-Control'
        CONTENT_LENGTH    = 'Content-Length'
        CONTENT_TYPE      = 'Content-Type'
        LOCATION          = 'Location'
        TRANSFER_ENCODING = 'Transfer-Encoding'
        X_CASCADE         = 'X-Cascade'
      else
        ALLOW             = 'allow'
        CACHE_CONTROL     = 'cache-control'
        CONTENT_LENGTH    = 'content-length'
        CONTENT_TYPE      = 'content-type'
        LOCATION          = 'location'
        TRANSFER_ENCODING = 'transfer-encoding'
        X_CASCADE         = 'x-cascade'
      end

      GET     = 'GET'
      POST    = 'POST'
      PUT     = 'PUT'
      PATCH   = 'PATCH'
      DELETE  = 'DELETE'
      HEAD    = 'HEAD'
      OPTIONS = 'OPTIONS'

      SUPPORTED_METHODS = [GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS].freeze
      SUPPORTED_METHODS_WITHOUT_OPTIONS = Grape::Util::LazyObject.new { [GET, POST, PUT, PATCH, DELETE, HEAD].freeze }

      HTTP_ACCEPT_VERSION    = 'HTTP_ACCEPT_VERSION'
      HTTP_TRANSFER_ENCODING = 'HTTP_TRANSFER_ENCODING'
      HTTP_ACCEPT            = 'HTTP_ACCEPT'

      FORMAT                 = 'format'

      HTTP_HEADERS = Grape::Util::LazyObject.new do
        common_http_headers = %w[
          Version
          Host
          Connection
          Cache-Control
          Dnt
          Upgrade-Insecure-Requests
          User-Agent
          Sec-Fetch-Dest
          Accept
          Sec-Fetch-Site
          Sec-Fetch-Mode
          Sec-Fetch-User
          Accept-Encoding
          Accept-Language
          Cookie
        ].freeze
        common_http_headers.each_with_object({}) do |header, response|
          response["HTTP_#{header.upcase.tr('-', '_')}"] = header
        end.freeze
      end

      def self.find_supported_method(route_method)
        Grape::Http::Headers::SUPPORTED_METHODS.detect { |supported_method| supported_method.casecmp(route_method).zero? }
      end
    end
  end
end
