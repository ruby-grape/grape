# frozen_string_literal: true

module Grape
  module Util
    # Base for classes which need to operate with own values kept
    # in the hash and inherited values kept in a Hash-like object.
    class BaseInheritable
      attr_accessor :inherited_values, :new_values

      # @param inherited_values [Object] An object implementing an interface
      #   of the Hash class.
      def initialize(inherited_values = nil)
        @inherited_values = inherited_values || {}
        @new_values = {}
      end

      def delete(*keys)
        keys.map do |key|
          # since delete returns the deleted value, seems natural to `map` the result
          new_values.delete key
        end
      end

      def initialize_copy(other)
        super
        self.inherited_values = other.inherited_values
        self.new_values = other.new_values.dup
      end

      def keys
        if new_values.any?
          inherited_values.keys.tap do |combined|
            combined.concat(new_values.keys)
            combined.uniq!
          end
        else
          inherited_values.keys
        end
      end

      def key?(name)
        inherited_values.key?(name) || new_values.key?(name)
      end
    end
  end
end
