# frozen_string_literal: true

module Grape
  class Endpoint
    # Remove in 5.0. Before 4.2.0 a route went through only the middleware,
    # filters and rescue handlers declared above it in its scope, the ones
    # its settings copy holds. Those declared below it now reach it too, and
    # for most of them nothing else would tell.
    module RegistrationsBelowWarning
      # The settings stores +use+ (and so +auth+), the callbacks and
      # +rescue_from+ each add an entry to on every call.
      STORE_KEYS = [:middleware, *Grape::Util::InheritableSetting::CALLBACK_STORE_KEYS.values, :rescue_options].freeze

      module_function

      # +above+ is the route's settings copy, +scope+ the live settings of the
      # scope it was declared in.
      def call(routes:, above:, scope:)
        return unless scope.registered_after?(above, STORE_KEYS)

        warn(
          "Grape: since 4.2.0, #{route_names(routes)} also goes through what is declared below it in the same scope: " \
          "#{declared_below(above, scope).join(', ')} (see UPGRADING.md). " \
          'Declare those above the route, or in a namespace holding only the routes they should cover.'
        )
      end

      def route_names(routes)
        routes.map { |route| "#{route.request_method} #{route.origin}" }.uniq.join(', ')
      end

      # Both hold the stores of the scopes around the route, so the scope's
      # own registrations below the route are what +scope+ holds beyond
      # +above+.
      def declared_below(above, scope)
        names = middleware_below(above, scope) + filters_below(above, scope)
        # Every +rescue_from+ stacks its options, and the latest one is read.
        names << '`rescue_from`' unless scope.rescue_options.equal?(above.rescue_options)
        names
      end

      def middleware_below(above, scope)
        scope.middleware.drop(above.middleware.size).map { |entry| middleware_name(*entry) }
      end

      def filters_below(above, scope)
        filters = above.callbacks
        scope.callbacks.filter_map { |phase, blocks| "`#{phase}`" if blocks.size > filters[phase].size }
      end

      def middleware_name(operation, middleware, options = nil, *)
        return "`auth :#{options[:type]}`" if middleware == Grape::Middleware::Auth::Base
        return "`use #{middleware}`" if operation == :use

        "`#{operation}`"
      end
    end
  end
end
