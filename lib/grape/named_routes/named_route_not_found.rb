module Grape
  module NamedRoutes
    class NamedRouteNotFound < StandardError
      attr_reader :missed_route

      def initialize(route_name)
        @missed_route = route_name
      end
    end
  end
end
