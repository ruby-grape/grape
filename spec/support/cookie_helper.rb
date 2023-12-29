# frozen_string_literal: true

module Spec
  module Support
    module Helpers
      def cookie_expires_value
        @cookie_expires_value ||= Gem::Version.new(Rack.release) <= Gem::Version.new('2') ? Time.at(0).gmtime.rfc2822 : Time.at(0).httpdate
      end

      def last_response_cookies
        Array(last_response.headers['Set-Cookie']).flat_map { |h| h.split("\n") }.sort
      end
    end
  end
end
