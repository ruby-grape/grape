# frozen_string_literal: true

require 'grape/router/attribute_translator'
require 'forwardable'

# Act like a Grape::Router::Route but for greedy_match
# see @neutral_map

module Grape
  class Router
    class GreedyRoute
      extend Forwardable

      attr_reader :index, :pattern, :options, :attributes

      delegate Grape::Router::AttributeTranslator::ROUTE_ATTRIBUTES => :@attributes

      def initialize(index:, pattern:, **options)
        @index = index
        @pattern = pattern
        @options = options
        @attributes = Grape::Router::AttributeTranslator.new(**options)
      end

      # Grape::Router:Route defines params as a function
      def params(_input = nil)
        @attributes.params || {}
      end
    end
  end
end
