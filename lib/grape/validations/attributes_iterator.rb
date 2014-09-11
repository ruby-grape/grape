module Grape
  module Validations
    class AttributesIterator
      include Enumerable

      def initialize(validator, scope, params)
        @attrs = validator.attrs
        @params = scope.params(params)
        @params = (@params.is_a?(Array) ? @params : [@params])
      end

      def each
        @params.each do |resource_params|
          @attrs.each do |attr_name|
            yield resource_params, attr_name
          end
        end
      end
    end
  end
end
