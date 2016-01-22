module Grape
  module Validations
    class AttributesIterator
      include Enumerable

      attr_reader :scope

      def initialize(validator, scope, params)
        @scope = scope
        @attrs = validator.attrs
        @params = Array.wrap(scope.params_with_index(params))
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
