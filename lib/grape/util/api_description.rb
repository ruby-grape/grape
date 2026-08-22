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
        @attributes = { description: }
        instance_eval(&)
      end

      DSL_METHODS.each do |attribute|
        define_method attribute do |value|
          @attributes[attribute] = value
        end
      end

      # The block form's aliases: writing +success+ stores under +:entity+ and
      # +failure+ under +:http_codes+, so a description always carries the
      # documented key whichever spelling was used.
      ALIASES = { success: :entity, failure: :http_codes }.freeze

      ALIASES.each { |from, to| alias_method from, to }

      # A Hash of options never reaches this class, so its +success+/+failure+
      # keys would survive unaliased. Rename them to keep both forms
      # equivalent; an explicit documented key wins over its alias.
      def self.normalize_aliases(options)
        return options unless options.keys.intersect?(ALIASES.keys)

        options.except(*ALIASES.keys).merge(
          ALIASES.filter_map do |from, to|
            [to, options[from]] if options.key?(from) && !options.key?(to)
          end.to_h
        )
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
