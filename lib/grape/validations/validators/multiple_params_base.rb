module Grape
  module Validations
    class MultipleParamsBase < Base
      # rubocop:disable HashEachMethods
      def validate!(params)
        attributes = AttributesIterator.new(self, @scope, params, multiple_params: true)
        array_errors = []

        attributes.each do |resource_params, _|
          begin
            validate_params!(resource_params)
          rescue Grape::Exceptions::Validation => e
            array_errors << e
          end
        end

        raise Grape::Exceptions::ValidationArrayErrors, array_errors if array_errors.any?
      end
      # rubocop:enable HashEachMethods

      private

      def keys_in_common(resource_params)
        return [] unless resource_params.is_a?(Hash)
        all_keys & resource_params.keys.map! { |attr| @scope.full_name(attr) }
      end

      def all_keys
        attrs.map { |attr| @scope.full_name(attr) }
      end
    end
  end
end
