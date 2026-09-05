# frozen_string_literal: true

module Grape
  class Router
    class Route < BaseRoute
      extend Forwardable

      FORWARD_MATCH_METHOD = ->(input, pattern) { input.start_with?(pattern.origin) }
      NON_FORWARD_MATCH_METHOD = ->(input, pattern) { pattern.match?(input) }

      attr_reader :app, :request_method, :index

      def_delegators :@app, :call

      def initialize(endpoint, method, pattern, options, forward_match:, params: {}, **route_attributes)
        super(pattern, options, **route_attributes)
        @app = endpoint
        @request_method = upcase_method(method)
        @match_function = forward_match ? FORWARD_MATCH_METHOD : NON_FORWARD_MATCH_METHOD
        @declared_params = params
      end

      def to_head
        head = dup
        head.convert_to_head_request!
        head
      end

      def apply(app)
        @app = app
        self
      end

      def match?(input)
        return false if input.blank?

        @match_function.call(input, pattern)
      end

      # The route's declared params keyed by name — path captures plus any
      # declared body/query params, as their definitions. Used for documentation
      # (e.g. grape-swagger), not for extracting request values.
      def params
        @params ||= pattern.captures_default.merge(@declared_params)
      end

      # Extract param values from a matched request path. Used by the router.
      #
      # A pattern with no named captures has nothing to extract, so it skips the
      # match entirely and answers nil — the same way {GreedyRoute#params_for}
      # does, and what the router already coerces into the Hash it builds
      # routing args in.
      def params_for(input)
        return unless pattern.captures?

        parsed = pattern.params(input)
        return unless parsed

        params = {}
        parsed.each { |name, value| params[name.to_sym] = tag_utf8!(value) unless value.nil? }
        params
      end

      protected

      def convert_to_head_request!
        @request_method = Rack::HEAD
      end

      private

      # Mustermann decodes path captures out of +PATH_INFO+, which Rack hands us
      # tagged ASCII-8BIT, so path params came back binary while Rack tags query
      # and body params UTF-8. That split makes an API's own declarations
      # disagree with themselves: `values: ['café']` matched `?id=café` but not
      # `/café`, since a binary string never equals the UTF-8 literal it was
      # written as.
      #
      # Re-tag as UTF-8. Nothing obliges a client to send UTF-8: the request
      # target is octets to HTTP, and Rack's SPEC has CGI keys carry non-ASCII
      # as ASCII-8BIT. But UTF-8 is what browsers percent-encode with, what an
      # IRI maps to, and what Rails settles on — ActionDispatch::Journey::Router
      # force_encodes every path capture to UTF-8 after unescaping it.
      #
      # Only the encoding changes; the bytes are untouched. Octets that are not
      # UTF-8 therefore stay invalid and are caught downstream rather than being
      # silently scrubbed into something the client never sent.
      #
      # The re-tag is in place, hence the bang. Mustermann's +Pattern#params+
      # builds a fresh Hash of fresh, unfrozen strings on every call and skips
      # its own Match cache, so the mutation cannot escape this request — which
      # is also what lets the Array branch re-tag its elements with +each+.
      def tag_utf8!(value)
        case value
        when String
          value.force_encoding(Encoding::UTF_8)
        when Array
          value.each { |v| tag_utf8!(v) }
        else
          # simplecov:disable
          # Unreachable: Mustermann's Pattern#params returns only String or
          # Array (of String) captures - see mustermann/pattern.rb#params,
          # mustermann/regexp_based.rb#params. params_for also filters out nil
          # before calling this, so there is no other value #tag_utf8! is ever
          # called with.
          value
          # simplecov:enable
        end
      end

      def upcase_method(method)
        method_s = method.to_s
        Grape::HTTP_SUPPORTED_METHODS.detect { |m| m.casecmp(method_s).zero? } || method_s.upcase
      end
    end
  end
end
