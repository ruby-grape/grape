module Grape
  module NamedRoutes
    class NamedRouteSeeker
      def initialize(app)
        @app = app
      end

      def find_endpoint(name)
        name_to_endpoint_hash[name.to_sym]
      end

      def find_endpoint!(name)
        fail NamedRouteNotFound.new(name), "Named route '#{name}' is missed." unless named_endpoint_present?(name)
        find_endpoint(name)
      end

      private

      def named_endpoint_present?(name)
        name_to_endpoint_hash.key?(name.to_sym)
      end

      def named_endpoints
        @named_endpoints ||= @app.endpoints.select do |endpoint|
          endpoint.options[:route_options].key?(:as)
        end
      end

      def name_to_endpoint_hash
        @name_to_endpoint_hash ||= named_endpoints.inject({}) do |hash, endpoint|
          endpoint_name = endpoint.options[:route_options][:as].to_sym
          hash[endpoint_name] = endpoint
          hash
        end
      end
    end
  end
end
