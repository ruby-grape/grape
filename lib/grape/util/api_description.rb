# frozen_string_literal: true

module Grape
  module Util
    class ApiDescription
      DSL_METHODS = %i[
        body_name
        consumes
        default_response
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
        @attributes = { description: }
        instance_eval(&)
      end

      DSL_METHODS.each do |attribute|
        define_method attribute do |value|
          @attributes[attribute] = value
        end
      end

      alias success entity
      alias failure http_codes

      # @deprecated Use {#default_response}. The description is read back
      #   through an ActiveSupport::OrderedOptions, where +default+ is
      #   +Hash#default+ rather than a key lookup, and grape-swagger has always
      #   asked the route for +default_response+.
      def default(value)
        Grape.deprecator.warn('`default` in a `desc` block is deprecated. Use `default_response` instead.')
        default_response(value)
      end

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
