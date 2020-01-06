# frozen_string_literal: true

require_relative 'base_inheritable'

module Grape
  module Util
    class StackableValues < BaseInheritable
      attr_reader :frozen_values

      def initialize(*_args)
        super

        @frozen_values = {}
      end

      # Even if there is no value, an empty array will be returned.
      def [](name)
        return @frozen_values[name] if @frozen_values.key? name

        inherited_value = @inherited_values[name]
        new_value = @new_values[name] || []

        return new_value unless inherited_value

        concat_values(inherited_value, new_value)
      end

      def []=(name, value)
        raise if @frozen_values.key? name
        @new_values[name] ||= []
        @new_values[name].push value
      end

      def to_hash
        keys.each_with_object({}) do |key, result|
          result[key] = self[key]
        end
      end

      def freeze_value(key)
        @frozen_values[key] = self[key].freeze
      end

      protected

      def concat_values(inherited_value, new_value)
        [].tap do |value|
          value.concat(inherited_value)
          value.concat(new_value)
        end
      end
    end
  end
end
