module Grape
  module ParameterTypes
    # Types representing a single value, which are coerced through Virtus
    # or special logic in Grape.
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
      Virtus::Attribute::Boolean,
      String,
      Symbol,
      Rack::Multipart::UploadedFile
    ]

    # Types representing data structures.
    STRUCTURES = [
      Hash,
      Array,
      Set
    ]

    # @param type [Class] type to check
    # @return [Boolean] whether or not the type is known by Grape as a valid
    #   type for a single value
    def self.primitive?(type)
      PRIMITIVES.include?(type)
    end

    # @param type [Class] type to check
    # @return [Boolean] whether or not the type is known by Grape as a valid
    #   data structure type
    # @note This method does not yet consider 'complex types', which inherit
    #   Virtus.model.
    def self.structure?(type)
      STRUCTURES.include?(type)
    end

    # A valid custom type must implement a class-level `parse` method, taking
    #   one String argument and returning the parsed value in its correct type.
    # @param type [Class] type to check
    # @return [Boolean] whether or not the type can be used as a custom type
    def self.custom_type?(type)
      !primitive?(type) &&
        !structure?(type) &&
        type.respond_to?(:parse) &&
        type.method(:parse).arity == 1
    end
  end
end
