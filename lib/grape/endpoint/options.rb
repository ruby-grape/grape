# frozen_string_literal: true

module Grape
  class Endpoint
    # Immutable value object holding the keyword inputs passed to
    # +Grape::Endpoint.new+. Internal to {Grape::Endpoint}, which builds it
    # from the +**options+ Hash in #initialize so the public +options+ reader
    # stays a plain Hash for downstream gems (e.g. grape-swagger).
    Options = Data.define(:path, :http_methods, :api, :route_options, :app, :params, :requirements, :anchor) do
      def initialize(path:, http_methods:, api:, route_options: {}, app: nil, params: {}, requirements: nil, anchor: true)
        # +Array()+ hands back the very Array it was given, so defaulting an
        # empty one by appending would append to the caller's Array — and raise
        # FrozenError on a frozen one. Build a new Array instead of growing
        # theirs: nothing about constructing an endpoint should be visible in
        # the path the caller passed in.
        paths = Array(path)
        super(
          path: paths.presence || ['/'],
          http_methods: Array(http_methods),
          api:, route_options:, app:, params:, requirements:, anchor:
        )
      end
    end
  end
end
