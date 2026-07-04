# frozen_string_literal: true

module Grape
  class Endpoint
    # Immutable value object holding the keyword inputs passed to
    # +Grape::Endpoint.new+. Internal to {Grape::Endpoint}, which builds it
    # from the +**options+ Hash in #initialize so the public +options+ reader
    # stays a plain Hash for downstream gems (e.g. grape-swagger).
    # +:method+ is renamed to +:http_methods+ on the value object to avoid
    # shadowing +Object#method+ via the generated Data accessor.
    Options = Data.define(:path, :http_methods, :for, :route_options, :app, :format) do
      def initialize(path:, method:, route_options: {}, app: nil, format: nil, **rest)
        path = Array(path)
        path << '/' if path.empty?
        super(path:, http_methods: Array(method), route_options:, app:, format:, **rest)
      end
    end
  end
end
