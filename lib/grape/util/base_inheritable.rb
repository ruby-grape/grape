# frozen_string_literal: true

module Grape
  module Util
    # Base for classes which need to operate with own values kept
    # in the hash and inherited values kept in a Hash-like object.
    #
    # +@new_values+ is lazily allocated on first write so settings layers
    # that only inherit (never override) don't carry an empty Hash each.
    class BaseInheritable
      attr_accessor :inherited_values, :new_values

      # @param inherited_values [Object] An object implementing an interface
      #   of the Hash class.
      def initialize(inherited_values = nil)
        @inherited_values = inherited_values || {}
        # @new_values stays nil until the first write.
      end

      def delete(*keys)
        return [] unless @new_values

        keys.map { |key| @new_values.delete(key) }
      end

      def initialize_copy(other)
        super
        @inherited_values = other.inherited_values
        @new_values = other.new_values&.dup
      end

      def keys
        return @inherited_values.keys if @new_values.nil? || @new_values.empty?

        (@inherited_values.keys + @new_values.keys).uniq
      end

      def key?(name)
        @inherited_values.key?(name) || @new_values&.key?(name) || false
      end
    end
  end
end
