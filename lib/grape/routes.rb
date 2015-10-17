module Grape
  module Routes
    # map route name to the route object
    @@routes = {}

    def self.[](route_name)
      @@routes[route_name]
    end

    def self.all
      @@routes.keys
    end

    def self.add(route)
      @@routes ||= {}

      route_path_name = route.route_path
      route_path_name = route_path_name.gsub(/^\//, "") # remove the first /
      route_path_name = route_path_name.gsub("/", "_") # to proper function-like name
      route_path_name = route_path_name.gsub(/(\(.+\))+/, "") # remove format
      route_path_name = "index" if route_path_name.empty?
      route_path_name << "_" + route.route_method.to_s.downcase
      route_path_name << "_path"
      route_path = route.route_path.gsub(/(\(.+\))/, "")

      if route_path_name =~ /:version_/i
        route_path_name = route_path_name.gsub(/:version_/i, "")
        Grape::Routes.class_eval do
          define_singleton_method route_path_name do |*args|
            if args.length != 1
              raise "Pass in version"
            end
            version = args[0]
            route_path.gsub(":version", version)
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

      @@routes[route_path_name] = route
      nil
    end
  end
end
