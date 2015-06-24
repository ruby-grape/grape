module Grape
  module NamedRouteMatcher
    def method_missing(method_id, *arguments)
      segments = arguments.first || {}

      route = Grape::API.all_routes.detect do |r|
        route_match?(r, method_id, segments)
      end

      if route
        route.send(method_id, *arguments)
      else
        super
      end
    end

    def route_match?(route, method_name, segments)
      return false unless route.respond_to?(method_name)
      fail ArgumentError,
           'Helper options must be a hash' unless segments.is_a?(Hash)
      requested_segments = segments.keys.map(&:to_s)
      route.uses_segments_in_path_helper?(requested_segments)
    end
  end
end
