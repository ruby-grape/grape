# frozen_string_literal: true

require 'grape/router/attribute_translator'
require 'forwardable'

module Grape
  class Router
    class GreedyRoute
      extend Forwardable

      attr_reader :index, :pattern, :options

      delegate Grape::Router::AttributeTranslator::ROUTE_ATTRIBUTES => :@attributes

      def initialize(index:, pattern:, **attributes)
        @index = index
        @pattern = pattern
        @options = attributes.delete(:options)
        @attributes = Grape::Router::AttributeTranslator.new(**attributes)
      end

      def params(_input = nil)
        @attributes.params || {}
      end
    end
  end
end


