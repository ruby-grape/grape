# frozen_string_literal: true

module Grape
  module Validations
    class MultipleAttributesIterator < AttributesIterator
      private

      def yield_attributes(resource_params)
        yield resource_params unless skip?(resource_params)
      end
    end
  end
end
