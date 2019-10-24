module Grape
  module Validations
    class SingleAttributeIterator < AttributesIterator
      private

      def yield_attributes(resource_params, attrs)
        attrs.each do |attr_name|
          yield resource_params, attr_name
        end
      end
    end
  end
end
