# frozen_string_literal: true

# Act like a Grape::Router::Route but for greedy_match
# see @neutral_map

module Grape
  class Router
    class GreedyRoute < BaseRoute
      extend Forwardable

      def_delegators :@endpoint, :call

      attr_reader :endpoint, :allow_header

      def initialize(pattern, endpoint:, allow_header:)
        super(pattern)
        @endpoint = endpoint
        @allow_header = allow_header
      end

      def params(_input = nil)
        nil
      end
    end
  end
end
