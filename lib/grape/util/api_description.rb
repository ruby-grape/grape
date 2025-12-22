# frozen_string_literal: true

module Grape
  module Util
    class ApiDescription
      DSL_METHODS = %i[
        body_name
        consumes
        default
        deprecated
        detail
        entity
        headers
        hidden
        http_codes
        is_array
        named
        nickname
        params
        produces
        security
        summary
        tags
      ].freeze

      def initialize(description, endpoint_configuration, &)
        @endpoint_configuration = endpoint_configuration
        @attributes = { description: description }
        instance_eval(&)
      end

      DSL_METHODS.each do |attribute|
        define_method attribute do |value|
          @attributes[attribute] = value
        end
      end

      alias success entity
      alias failure http_codes

      def configuration
        @configuration ||= eval_endpoint_config(@endpoint_configuration)
      end

      def settings
        @attributes
      end

      private

      def eval_endpoint_config(configuration)
        return configuration if configuration.is_a?(Hash)

        configuration.evaluate
      end
    end
  end
end
