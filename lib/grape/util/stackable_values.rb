# frozen_string_literal: true

module Grape
  module Util
    # A read-only view of one settings scope's stackable registrations.
    #
    # Grape stores nothing here anymore: the registrations live on
    # Grape::Util::InheritableSetting, one Array per key per scope, and are
    # reached through its semantic accessors (+helpers+, +middleware+,
    # +namespaces+, ...). This class survives only because grape-swagger
    # reads InheritableSetting#namespace_stackable directly — including
    # walking the #inherited_values chain and reading each level's own
    # #new_values to recover per-scope registrations — and is expected to be
    # removed once grape-swagger reads those accessors instead.
    #
    # Instances are built on demand by InheritableSetting#namespace_stackable
    # and are not the backing store: writing to #new_values does not register
    # anything.
    class StackableValues
      EMPTY = [].freeze

      attr_reader :inherited_values, :new_values

      # @param new_values [Hash, nil] the scope's own registrations, one Array
      #   per key; nil when the scope never registered anything.
      # @param inherited_values [StackableValues, Hash] the enclosing scope's
      #   view, or an empty Hash at the root of the chain.
      def initialize(new_values, inherited_values)
        @new_values = new_values
        @inherited_values = inherited_values
      end

      # Outermost scope first. Even if there is no value, an empty (frozen)
      # array will be returned.
      def [](name)
        inherited_value = @inherited_values[name]
        new_value = @new_values && @new_values[name]

        return new_value || EMPTY unless inherited_value

        concat_values(inherited_value, new_value)
      end

      def keys
        return @inherited_values.keys if @new_values.nil? || @new_values.empty?

        (@inherited_values.keys + @new_values.keys).uniq
      end

      def to_hash
        keys.to_h do |key|
          [key, self[key]]
        end
      end

      protected

      def concat_values(inherited_value, new_value)
        return inherited_value unless new_value

        inherited_value + new_value
      end
    end
  end
end
