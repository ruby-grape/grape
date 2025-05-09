# frozen_string_literal: true

require 'uri'
module Spec
  module Support
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
    class CookieJar
      attr_reader :attributes

      def initialize(raw)
        @attributes = raw.split(/;\s*/).flat_map.with_index do |attribute, i|
          attribute, value = attribute.split('=', 2)
          if i.zero?
            [['name', attribute], ['value', unescape(value)]]
          else
            [[attribute.downcase, parse_value(attribute, value)]]
          end
        end.to_h.freeze
      end

      def to_h
        @attributes.dup
      end

      def to_s
        @attributes.to_s
      end

      private

      def unescape(value)
        URI.decode_www_form_component(value, Encoding::UTF_8)
      end

      def parse_value(attribute, value)
        case attribute
        when 'expires'
          Time.parse(value)
        when 'max-age'
          value.to_i
        when 'secure', 'httponly', 'partitioned'
          true
        else
          unescape(value)
        end
      end
    end
  end
end

module Rack
  class MockResponse
    def cookie_jar
      @cookie_jar ||= Array(headers[Rack::SET_COOKIE]).flat_map { |h| h.split("\n") }.map { |c| Spec::Support::CookieJar.new(c).to_h }
    end
  end
end
