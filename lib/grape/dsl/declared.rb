# frozen_string_literal: true

module Grape
  module DSL
    module Declared
      # Denotes a situation where a DSL method has been invoked in a
      # filter which it should not yet be available in
      class MethodNotYetAvailable < StandardError
        def initialize(msg = '#declared is not available prior to parameter validation')
          super
        end
      end

      # A filtering method that will return a hash
      # consisting only of keys that have been declared by a
      # `params` statement against the current/target endpoint or parent
      # namespaces.
      # @param params [Hash] The initial hash to filter. Usually this will just be `params`
      # @param options [Hash] Can pass `:include_missing`, `:stringify` and `:include_parent_namespaces`
      # options. `:include_parent_namespaces` defaults to true, hence must be set to false if
      # you want only to return params declared against the current/target endpoint.
      def declared(passed_params, include_parent_namespaces: true, include_missing: true, evaluate_given: false, stringify: false)
        raise MethodNotYetAvailable unless before_filter_passed

        contract_key_map = inheritable_setting.namespace_stackable[:contract_key_map]
        handler = DeclaredParamsHandler.new(include_missing:, evaluate_given:, stringify:, contract_key_map: contract_key_map)
        declared_params = include_parent_namespaces ? inheritable_setting.route[:declared_params] : (inheritable_setting.namespace_stackable[:declared_params].last || [])
        renamed_params = inheritable_setting.route[:renamed_params] || {}
        route_params = options.dig(:route_options, :params) || {} # options = endpoint's option

        handler.call(passed_params, declared_params, route_params, renamed_params)
      end
    end
  end
end
