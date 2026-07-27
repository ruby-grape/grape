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

      # Two layers over the same inherited store resolve identically when their
      # own overrides match, which equality checks first so the common case
      # never merges either side down. Since +@new_values+ is allocated lazily,
      # nil and an empty Hash both mean "this layer overrides nothing". Layers
      # that fail that check can still resolve identically — an override may
      # merely restate an inherited value — so they fall back to #to_hash.
      def ==(other)
        return true if equal?(other)
        return false unless other.is_a?(self.class)
        return true if inherited_values == other.inherited_values && same_overrides?(other)

        to_hash == other.to_hash
      end
      alias eql? ==

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

      private

      # Whether both layers override the same keys with the same values, with
      # nil and an empty Hash treated alike (see #==).
      def same_overrides?(other)
        return other.new_values.blank? if new_values.blank?

        new_values == other.new_values
      end
    end
  end
end
