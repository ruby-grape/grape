# frozen_string_literal: true

module Grape
  class Endpoint
    # Remove in 5.0, with InheritableSetting#settled_otherwise?. Before 4.2.0
    # a route declared in a namespace read the settings of the scopes around
    # it as they stood once the API was defined, so a +format+ or +version+
    # declared after the namespace applied to it, while a route declared
    # directly in the scope kept the one above it. Both now keep the one
    # above them, and for most settings nothing else would tell.
    module SettingsAfterNamespaceWarning
      # The settings a route reads, by the DSL method that assigns them.
      DSL_NAMES = {
        format: 'format', default_format: 'default_format', default_error_formatter: 'default_error_formatter',
        default_error_status: 'default_error_status', version: 'version', version_options: 'version',
        root_prefix: 'prefix', build_params_with: 'build_with', do_not_route_head: 'do_not_route_head!'
      }.freeze
      KEYS = DSL_NAMES.keys.freeze

      module_function

      # +setting+ is the route's settings copy.
      def call(routes:, setting:)
        return unless setting.changed_since_settled? && KEYS.any? { |key| setting.settled_otherwise?(key) }

        warn(
          "Grape: since 4.2.0, #{route_names(routes)} no longer takes the #{setting_names(setting)} declared after a namespace it is in " \
          '(see UPGRADING.md). Declare settings above the namespaces they apply to.'
        )
      end

      def route_names(routes)
        routes.map { |route| "#{route.request_method} #{route.origin}" }.uniq.join(', ')
      end

      # Not Array#to_sentence, which would load the I18n translations.
      def setting_names(setting)
        *names, last = KEYS.filter_map { |key| "`#{DSL_NAMES[key]}`" if setting.settled_otherwise?(key) }.uniq
        names.empty? ? last : "#{names.join(', ')} and #{last}"
      end
    end
  end
end
