# frozen_string_literal: true

module Grape
  module Validations
    module Types
      # This class wraps {MultipleTypeCoercer}, for use with collections
      # that allow members of more than one type.
      class VariantCollectionCoercer
        extend Grape::Util::FreezeOnNew

        # @return [Array<Class>,Set<Class>] the member types as declared in the DSL
        attr_reader :types

        # Construct a new coercer that will attempt to coerce
        # a list of values such that all members are of one of
        # the given types. The container may also optionally be
        # coerced to a +Set+. An arbitrary coercion +method+ may
        # be supplied, which will be passed the entire collection
        # as a parameter and should return a new collection, or
        # may return the same one if no coercion was required.
        #
        # @param types [Array<Class>,Set<Class>] list of allowed types,
        #   also specifying the container type
        # @param method [#call,#parse] method by which values should be coerced
        def initialize(types, method = nil)
          @types = types
          @method = method.respond_to?(:parse) ? method.method(:parse) : method

          # If we have a coercion method, pass it in here to save
          # building another one, even though we call it directly.
          @member_coercer = MultipleTypeCoercer.new types, method
        end

        # Returns the Grape DSL notation for this coercer, e.g. "Array[Integer, String]".
        # Distinct from the plain-array string "[Integer, String]" produced by the
        # +types:+ keyword, which lets documentation tools tell the two apart.
        def to_s
          container = @types.is_a?(Set) ? 'Set' : 'Array'
          "#{container}[#{@types.join(', ')}]"
        end

        # Coerce the given value.
        #
        # A value that is not an Array, and an Array holding a member none of
        # the types accepts, are invalid, as they are for a collection of one
        # type. A coercion method is handed the value whatever it is, as it is
        # for +types:+, so it can build the collection out of a String.
        #
        # @param value [Array<String>] collection of values to be coerced
        # @return [Array<Object>,Set<Object>,InvalidValue,nil]
        #   the coerced result, nil when the value is nil or an empty String,
        #   or an instance of {InvalidValue} if the value could not be coerced.
        def call(value)
          return if value.nil? || (value.is_a?(String) && value.empty?)

          coerced = @method ? @method.call(value) : coerce_members(value)
          return coerced if coerced.is_a?(InvalidValue)
          return Set.new coerced if @types.is_a? Set

          coerced
        end

        private

        def coerce_members(value)
          return InvalidValue.new unless value.is_a?(Array)

          value.map do |member|
            coerced = @member_coercer.call(member)
            return coerced if coerced.is_a?(InvalidValue)

            coerced
          end
        end
      end
    end
  end
end
