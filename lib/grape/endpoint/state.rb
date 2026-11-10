# frozen_string_literal: true

module Grape
  class Endpoint
    # Everything an endpoint's requests read from it and none of them changes.
    # Each request's copy of the endpoint holds this and its own state, and
    # nothing else of the endpoint. +app+, +callbacks+, +build_params_with+,
    # +undeclared_params+ and +declared_params+ are filled in by
    # Endpoint#compile!.
    State = Data.define(:inheritable_setting, :options, :config, :source, :options_route_enabled, :app, :callbacks, :build_params_with,
                        :undeclared_params, :declared_params) do
      def initialize(inheritable_setting:, options:, config:, source:, options_route_enabled: false, app: nil, callbacks: nil,
                     build_params_with: nil, undeclared_params: nil, declared_params: nil)
        super
      end
    end
  end
end
