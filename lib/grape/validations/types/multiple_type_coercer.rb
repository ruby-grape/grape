module Grape
  module Validations
    module Types
      # This class is intended for use with Grape endpoint parameters that
      # have been declared to be of variant-type using the +:types+ option.
      # +MultipleTypeCoercer+ will build a coercer for each type declared
      # in the array passed to +:types+ using {Types.build_coercer}. It will
      # apply these coercers to parameter values in the order given to
      # +:types+, and will return the value returned by the first coercer
      # to successfully coerce the parameter value. Therefore if +String+ is
      # an allowed type it should be declared last, since it will always
      # successfully "coerce" the value.
      class MultipleTypeCoercer
        # Construct a new coercer that will attempt to coerce
        # values to the given list of types in the given order.
        #
        # @param types [Array<Class>] list of allowed types
        # @param method [#call,#parse] method by which values should be
        #   coerced. See class docs for default behaviour.
        def initialize(types, method = nil)
          @method = method.respond_to?(:parse) ? method.method(:parse) : method

          @type_coercers = types.map do |type|
            if Types.multiple? type
              VariantCollectionCoercer.new type
            else
              Types.build_coercer type
            end
          end
        end

        # This method is called from somewhere within
        # +Virtus::Attribute::coerce+ in order to coerce
        # the given value.
        #
        # @param value [String] value to be coerced, in grape
        #   this should always be a string.
        # @return [Object,InvalidValue] the coerced result, or an instance
        #   of {InvalidValue} if the value could not be coerced.
        def call(value)
          return @method.call(value) if @method

          @type_coercers.each do |coercer|
            coerced = coercer.coerce(value)

            return coerced if coercer.value_coerced? coerced
          end

          # Declare that we couldn't coerce the value in such a way
          # that Grape won't ask us again if the value is valid
          InvalidValue.new
        end

        # This method is called from somewhere within
        # +Virtus::Attribute::value_coerced?+ in order to
        # assert that the value has been coerced successfully.
        # Due to Grape's design this will in fact only be called
        # if a custom coercion method is being used, since {#call}
        # returns an {InvalidValue} object if the value could not
        # be coerced.
        #
        # @param _primitive [Axiom::Types::Type] primitive type
        #   for the coercion as detected by axiom-types' inference
        #   system. For custom types this is typically not much use
        #   (i.e. it is +Axiom::Types::Object+) unless special
        #   inference rules have been declared for the type.
        # @param value [Object] a coerced result returned from {#call}
        # @return [true,false] whether or not the coerced value
        #   satisfies type requirements.
        def success?(_primitive, value)
          @type_coercers.any? { |coercer| coercer.value_coerced? value }
        end
      end
    end
  end
end
