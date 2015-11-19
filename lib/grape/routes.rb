module Grape
  module Routes
    class << self
      # map route name to the route object
      attr_accessor :routes
    end

    def self.[](route_name)
      routes[route_name]
    end

    def self.all
      routes.keys
    end

    def self.add(route)
      self.routes ||= {}

      route_path_name = route.route_path
      route_path_name = route_path_name.gsub(%r{^\/}, '') # remove the first /
      route_path_name = route_path_name.tr('/', '_') # to proper function-like name
      route_path_name = route_path_name.gsub(/(\(.+\))+/, '') # remove format
      route_path_name = 'index' if route_path_name.empty?
      route_path_name << '_' + route.route_method.to_s.downcase
      route_path_name << '_path'
      route_path = route.route_path.gsub(/(\(.+\))/, '')

      if route_path_name =~ /:version_/i
        route_path_name = route_path_name.gsub(/:version_/i, '')
        Grape::Routes.class_eval do
          define_singleton_method route_path_name do |*args|
            fail 'Pass in version' if args.length != 1
            version = args[0]
            route_path.gsub(':version', version)
          end
        end
      else
        # define on-the-fly helper function
        Grape::Routes.class_eval do
          define_singleton_method route_path_name do
            route_path
          end
        end
      end

      routes[route_path_name] = route
      nil
    end
  end
end
