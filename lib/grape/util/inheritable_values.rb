# frozen_string_literal: true

module Grape
  module Util
    class InheritableValues < BaseInheritable
      def [](name)
        return @inherited_values[name] unless @new_values

        @new_values.fetch(name) { @inherited_values[name] }
      end

      def []=(name, value)
        (@new_values ||= {})[name] = value
      end

      def merge(new_hash)
        values.merge!(new_hash)
      end

      def to_hash
        values
      end

      protected

      def values
        return @inherited_values.merge(@new_values) if @new_values && !@new_values.empty?

        @inherited_values.is_a?(Hash) ? @inherited_values.dup : @inherited_values.to_hash
      end
    end
  end
end
