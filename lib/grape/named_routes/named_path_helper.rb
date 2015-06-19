module Grape
  module NamedRoutes
    module NamedPathHelper
      def get_named_path(route_name, route_params = {})
        endpoint = named_route_seeker.find_endpoint!(route_name)
        NamedRoutes::PathCompiler.compile_path(endpoint.routes.first, route_params)
      end

      def named_route_seeker
        @named_route_seeker ||= NamedRoutes::NamedRouteSeeker.new(self)
      end

      def method_missing(method, *arguments)
        if method =~ /\w+_path/
          route_name = method.to_s.sub(/_path$/, '')
          endpoint = named_route_seeker.find_endpoint(route_name)
        end

        if endpoint
          NamedRoutes::PathCompiler.compile_path(endpoint.routes.first, arguments.first || {})
        else
          super
        end
      end
    end
  end
end
