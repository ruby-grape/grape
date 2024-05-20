# frozen_string_literal: true

# Act like a Grape::Router::Route but for greedy_match
# see @neutral_map

module Grape
  class Router
    class GreedyRoute < BaseRoute
      def initialize(pattern:, **options)
        @pattern = pattern
        super(**options)
      end

      # Grape::Router:Route defines params as a function
      def params(_input = nil)
        options[:params] || {}
      end
    end
  end
end
