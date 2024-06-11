# frozen_string_literal: true

module Grape
  module Http
    module Headers
      HTTP_ACCEPT_VERSION = 'HTTP_ACCEPT_VERSION'
      HTTP_ACCEPT = 'HTTP_ACCEPT'
      HTTP_TRANSFER_ENCODING = 'HTTP_TRANSFER_ENCODING'

      ALLOW = 'Allow'
      LOCATION = 'Location'
      X_CASCADE = 'X-Cascade'
      TRANSFER_ENCODING = 'Transfer-Encoding'

      SUPPORTED_METHODS = [
        Rack::GET,
        Rack::POST,
        Rack::PUT,
        Rack::PATCH,
        Rack::DELETE,
        Rack::HEAD,
        Rack::OPTIONS
      ].freeze

      SUPPORTED_METHODS_WITHOUT_OPTIONS = (SUPPORTED_METHODS - [Rack::OPTIONS]).freeze

      HTTP_HEADERS = Grape::Util::Lazy::Object.new do
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
