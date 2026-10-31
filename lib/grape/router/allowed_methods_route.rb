# frozen_string_literal: true

module Grape
  class Router
    # Stands in for a Grape::Router::Route on a path, whatever the HTTP method:
    # it answers a method the path has no route for with the methods it does,
    # as a 405 or an auto-OPTIONS. Never runs a route's block. See @neutral_map.
    class AllowedMethodsRoute < BaseRoute
      extend Forwardable

      def_delegators :@endpoint, :call

      attr_reader :endpoint, :allow_header

      def initialize(pattern, endpoint:, allow_header:)
        super(pattern)
        @endpoint = endpoint
        @allow_header = allow_header
      end

      def params
        nil
      end

      def params_for(_input, _match = nil, _captures = nil)
        nil
      end
    end
  end
end
