# frozen_string_literal: true

module Grape
  module Util
    # A settings scope's own values layered over the enclosing scope's, the
    # nearest scope winning on read. Used for the nearest-wins scalar settings
    # behind Grape::Util::InheritableSetting; stacking registrations are kept
    # by the setting itself.
    #
    # +@new_values+ is lazily allocated on first write so settings layers
    # that only inherit (never override) don't carry an empty Hash each.
    class InheritableValues
      attr_accessor :inherited_values, :new_values

      # @param inherited_values [Object] An object implementing an interface
      #   of the Hash class.
      def initialize(inherited_values = nil)
        @inherited_values = inherited_values || {}
        # @new_values stays nil until the first write.
      end

      def [](name)
        return @inherited_values[name] unless @new_values

        @new_values.fetch(name) { @inherited_values[name] }
      end

      def []=(name, value)
        (@new_values ||= {})[name] = value
      end

      def delete(*keys)
        return [] unless @new_values

        keys.map { |key| @new_values.delete(key) }
      end

      def key?(name)
        @inherited_values.key?(name) || @new_values&.key?(name) || false
      end

      def merge(new_hash)
        values.merge!(new_hash)
      end

      def to_hash
        values
      end

      def initialize_copy(other)
        super
        @inherited_values = other.inherited_values
        @new_values = other.new_values&.dup
      end

      protected

      def values
        return @inherited_values.merge(@new_values) if @new_values && !@new_values.empty?

        @inherited_values.is_a?(Hash) ? @inherited_values.dup : @inherited_values.to_hash
      end
    end
  end
end
