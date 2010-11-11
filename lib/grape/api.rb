require 'rack/mount'

module Grape
  class API
    class << self
      attr_reader :route_set
      
      def reset!
        @settings = [{}]
        @route_set = Rack::Mount::RouteSet.new
        @prototype = nil
      end
      
      def call(env)
        route_set.freeze.call(env)
      end
      
      # Settings are a stack, so when we
      # want to access them they are merged
      # in the order pushed.
      def settings
        @settings.inject({}){|f,h| f.merge!(h); f}
      end
      
      def set(key, value)
        @settings.last[key.to_sym] = value
      end
      
      # Define a root prefix for your entire
      # API. For instance, if you had an api
      # that you wanted to be namespaced at
      # `/api/` you would do this:
      # 
      #   prefix '/api'
      def prefix(prefix = nil)
        prefix ? set(:root_prefix, prefix) : settings[:root_prefix]
      end
      
      def version(new_version = nil)
        new_version ? set(:version, new_version) : settings[:version]
      end
      
      def default_format(new_format = nil)
        new_format ? set(:default_format, new_format.to_sym) : settings[:default_format]
      end
      
      def route_set
        @route_set ||= Rack::Mount::RouteSet.new
      end
      
      def compile_path(path)
        parts = []
        parts << prefix if prefix
        parts << version if version
        parts << path
        Rack::Mount::Utils.normalize_path(parts.join('/'))
      end

      def route(method, path_info, &block)
        route_set.add_route(build_endpoint(&block), :path_info => compile_path(path_info))
      end
      
      def build_endpoint(&block)
        builder = Rack::Builder.new
        builder.use Grape::Middleware::Error
        builder.use Grape::Middleware::Prefixer, :prefix => prefix if prefix        
        builder.use Grape::Middleware::Versioner if version
        builder.use Grape::Middleware::Formatter, :default_format => default_format || :json
        builder.run Grape::Endpoint.new(&block)
        builder.to_app
      end
      
      def get(path_info, &block); route('GET', path_info, &block) end
      def post(path_info, &block); route('POST', path_info, &block) end
      def put(path_info, &block); route('PUT', path_info, &block) end
      
      def inherited(subclass)
        subclass.reset!
      end
    end  
    
    reset! 
  end
end