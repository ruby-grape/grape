module Grape
  module Validations
    module Types
      # Work out the +Virtus::Attribute+ object to
      # use for coercing strings to the given +type+.
      # Coercion +method+ will be inferred if none is
      # supplied.
      #
      # If a +Virtus::Attribute+ object already built
      # with +Virtus::Attribute.build+ is supplied as
      # the +type+ it will be returned and +method+
      # will be ignored.
      #
      # See {CustomTypeCoercer} for further details
      # about coercion and type-checking inference.
      #
      # @param type [Class] the type to which input strings
      #   should be coerced
      # @param method [Class,#call] the coercion method to use
      # @return [Virtus::Attribute] object to be used
      #   for coercion and type validation
      def self.build_coercer(type, method = nil)
        # Accept pre-rolled virtus attributes without interference
        return type if type.is_a? Virtus::Attribute

        converter_options = {
          nullify_blank: true
        }
        conversion_type = if method == JSON
                            Object
                            # because we want just parsed JSON content:
                            # if type is Array and data is `"{}"`
                            # result will be [] because Virtus converts hashes
                            # to arrays
                          else
                            type
                          end

        # Use a special coercer for multiply-typed parameters.
        if Types.multiple?(type)
          converter_options[:coercer] = Types::MultipleTypeCoercer.new(type, method)
          conversion_type = Object

        # Use a special coercer for custom types and coercion methods.
        elsif method || Types.custom?(type)
          converter_options[:coercer] = Types::CustomTypeCoercer.new(type, method)

        # Grape swaps in its own Virtus::Attribute implementations
        # for certain special types that merit first-class support
        # (but not if a custom coercion method has been supplied).
        elsif Types.special?(type)
          conversion_type = Types::SPECIAL[type]
        end

        # Virtus will infer coercion and validation rules
        # for many common ruby types.
        Virtus::Attribute.build(conversion_type, converter_options)
      end
    end
  end
end
