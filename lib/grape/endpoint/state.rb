# frozen_string_literal: true

module Grape
  class Endpoint
    # Everything an endpoint's requests read from it and none of them changes.
    # Each request's copy of the endpoint holds this and its own state, and
    # nothing else of the endpoint. +app+, +callbacks+ and +build_params_with+
    # are filled in by Endpoint#compile!.
    State = Data.define(:inheritable_setting, :options, :config, :source, :options_route_enabled, :app, :callbacks, :build_params_with) do
      def initialize(inheritable_setting:, options:, config:, source:, options_route_enabled: false, app: nil, callbacks: nil, build_params_with: nil)
        super
      end
    end
  end
end
