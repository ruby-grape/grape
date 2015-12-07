module Grape
  module Validations
    class AttributesIterator
      include Enumerable

      attr_reader :scope

      def initialize(validator, scope, params)
        @scope = scope
        @attrs = validator.attrs
        @params = Array.wrap(scope.params(params))
      end

      def each
        @params.each do |resource_params|
          @attrs.each_with_index do |attr_name, index|
            if resource_params.is_a?(Hash) && resource_params[attr_name].is_a?(Array)
              scope.index = index
            end
            yield resource_params, attr_name
          end
        end
      end
    end
  end
end
