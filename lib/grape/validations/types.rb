# frozen_string_literal: true

module Grape
  module Validations
    # Module for code related to grape's system for
    # coercion and type validation of incoming request
    # parameters.
    #
    # Grape uses a number of tests and assertions to
    # work out exactly how a parameter should be handled,
    # based on the +type+ and +coerce_with+ options that
    # may be supplied to {Grape::Dsl::Parameters#requires}
    # and {Grape::Dsl::Parameters#optional}. The main
    # entry point for this process is {Types.build_coercer}.
    module Types
      module_function

      PRIMITIVES = [
        # Numerical
        Integer,
        Float,
        BigDecimal,
        Numeric,

        # Date/time
        Date,
        DateTime,
        Time,

        # Misc
        Grape::API::Boolean,
        String,
        Symbol,
        TrueClass,
        FalseClass
      ].freeze

      # Types representing data structures.
      STRUCTURES = [Hash, Array, Set].freeze

      SPECIAL = {
        ::JSON => Json,
        Array[JSON] => JsonArray,
        ::File => File,
        Rack::Multipart::UploadedFile => File
      }.freeze

      GROUPS = [Array, Hash, JSON, Array[JSON]].freeze

      # Is the given class a primitive type as recognized by Grape?
      #
      # @param type [Class] type to check
      # @return [Boolean] whether or not the type is known by Grape as a valid
      #   type for a single value
      def primitive?(type)
        PRIMITIVES.include?(type)
      end

      # Is the given class a standard data structure (collection or map)
      # as recognized by Grape?
      #
      # @param type [Class] type to check
      # @return [Boolean] whether or not the type is known by Grape as a valid
      #   data structure type
      def structure?(type)
        STRUCTURES.include?(type)
      end

      # Is the declared type in fact an array of multiple allowed types?
      # For example the declaration +types: [Integer,String]+ will attempt
      # first to coerce given values to integer, but will also accept any
      # other string.
      #
      # @param type [Array<Class>,Set<Class>] type (or type list!) to check
      # @return [Boolean] +true+ if the given value will be treated as
      #   a list of types.
      def multiple?(type)
        (type.is_a?(Array) || type.is_a?(Set)) && type.size > 1
      end

      # Does Grape provide special coercion and validation
      # routines for the given class? This does not include
      # automatic handling for primitives, structures and
      # otherwise recognized types. See {Types::SPECIAL}.
      #
      # @param type [Class] type to check
      # @return [Boolean] +true+ if special routines are available
      def special?(type)
        SPECIAL.key? type
      end

      # Is the declared type a supported group type?
      # Currently supported group types are Array, Hash, JSON, and Array[JSON]
      #
      # @param type [Array<Class>,Class] type to check
      # @return [Boolean] +true+ if the type is a supported group type
      def group?(type)
        GROUPS.include? type
      end

      # A valid custom type must implement a class-level `parse` method, taking
      # one String argument and returning the parsed value in its correct type.
      #
      # @param type [Class] type to check
      # @return [Boolean] whether or not the type can be used as a custom type
      def custom?(type)
        !primitive?(type) &&
          !structure?(type) &&
          !multiple?(type) &&
          type.respond_to?(:parse) &&
          type.method(:parse).arity == 1
      end

      # Is the declared type an +Array+ or +Set+ of a {#custom?} type?
      #
      # @param type [Array<Class>,Class] type to check
      # @return [Boolean] true if +type+ is a collection of a type that implements
      #   its own +#parse+ method.
      def collection_of_custom?(type)
        (type.is_a?(Array) || type.is_a?(Set)) &&
          type.length == 1 &&
          (custom?(type.first) || special?(type.first))
      end

      def map_special(type)
        SPECIAL.fetch(type, type)
      end

      # Chooses the best coercer for the given type. For example, if the type
      # is Integer, it will return a coercer which will be able to coerce a value
      # to the integer.
      #
      # There are a few very special coercers which might be returned.
      #
      # +Grape::Types::MultipleTypeCoercer+ is a coercer which is returned when
      # the given type implies values in an array with different types.
      # For example, +[Integer, String]+ allows integer and string values in
      # an array.
      #
      # +Grape::Types::CustomTypeCoercer+ is a coercer which is returned when
      # a method is specified by a user with +coerce_with+ option or the user
      # specifies a custom type which implements requirments of
      # +Grape::Types::CustomTypeCoercer+.
      #
      # +Grape::Types::CustomTypeCollectionCoercer+ is a very similar to the
      # previous one, but it expects an array or set of values having a custom
      # type implemented by the user.
      #
      # There is also a group of custom types implemented by Grape, check
      # +Grape::Validations::Types::SPECIAL+ to get the full list.
      #
      # @param type [Class] the type to which input strings
      #   should be coerced
      # @param method [Class,#call] the coercion method to use
      # @return [Object] object to be used
      #   for coercion and type validation
      def build_coercer(type, method: nil, strict: false)
        # no cache since unique
        return create_coercer_instance(type, method, strict) if method.respond_to?(:call)

        CoercerCache[[type, method, strict]]
      end

      def create_coercer_instance(type, method, strict)
        # Maps a custom type provided by Grape, it doesn't map types wrapped by collections!!!
        type = Types.map_special(type)

        # Use a special coercer for multiply-typed parameters.
        if Types.multiple?(type)
          MultipleTypeCoercer.new(type, method)

          # Use a special coercer for custom types and coercion methods.
        elsif method || Types.custom?(type)
          CustomTypeCoercer.new(type, method)

          # Special coercer for collections of types that implement a parse method.
          # CustomTypeCoercer (above) already handles such types when an explicit coercion
          # method is supplied.
        elsif Types.collection_of_custom?(type)
          Types::CustomTypeCollectionCoercer.new(
            Types.map_special(type.first), type.is_a?(Set)
          )
        else
          DryTypeCoercer.coercer_instance_for(type, strict)
        end
      end

      class CoercerCache < Grape::Util::Cache
        def initialize
          super
          @cache = Hash.new do |h, (type, method, strict)|
            h[[type, method, strict]] = Grape::Validations::Types.create_coercer_instance(type, method, strict)
          end
        end
      end
    end
  end
end
