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

      # A greedy route matches by prefix and captures nothing, so it has neither
      # declared params to document nor values to extract. Both are defined
      # explicitly: {Grape::Router#process_route} calls +params_for+ on whatever
      # route it matched, and BaseRoute no longer forwards unknown names to
      # +@options+ (where an OrderedOptions lookup would answer nil by accident).
      def params
        nil
      end

      def params_for(_input)
        nil
      end
    end
  end
end
