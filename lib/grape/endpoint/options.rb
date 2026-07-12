# frozen_string_literal: true

module Grape
  class Endpoint
    # Immutable value object holding the keyword inputs passed to
    # +Grape::Endpoint.new+. Internal to {Grape::Endpoint}, which builds it
    # from the +**options+ Hash in #initialize so the public +options+ reader
    # stays a plain Hash for downstream gems (e.g. grape-swagger).
    Options = Data.define(:path, :http_methods, :api, :route_options, :app, :params, :requirements, :anchor) do
      def initialize(path:, http_methods:, api:, route_options: {}, app: nil, params: {}, requirements: nil, anchor: true)
        path = Array(path)
        path << '/' if path.empty?
        http_methods = Array(http_methods)
        super
      end
    end
  end
end
