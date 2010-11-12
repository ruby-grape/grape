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
      
      def settings_stack
        @settings
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
      
      def auth(type = nil, &block)
        if type
          set(:auth, {:type => type.to_sym, :proc => block})
        else
          settings[:auth]
        end
      end
      
      def http_basic(&block)
        auth :http_basic, &block
      end
      
      def route_set
        @route_set ||= Rack::Mount::RouteSet.new
      end
      
      def compile_path(path)
        parts = []
        parts << prefix if prefix
        parts << version if version
        parts << namespace if namespace
        parts << path
        Rack::Mount::Utils.normalize_path(parts.join('/'))
      end

      def route(method, path_info, &block)
        route_set.add_route(build_endpoint(&block), 
          :path_info => compile_path(path_info), 
          :request_method => method
        )
      end
      
      def build_endpoint(&block)
        b = Rack::Builder.new
        b.use Grape::Middleware::Error
        b.use Grape::Middleware::Auth::Basic, &settings[:auth][:proc] if settings[:auth] && settings[:auth][:type] == :http_basic
        b.use Grape::Middleware::Prefixer, :prefix => prefix if prefix        
        b.use Grape::Middleware::Versioner if version
        b.use Grape::Middleware::Formatter, :default_format => default_format || :json
        b.run Grape::Endpoint.new(&block)
        b.to_app
      end
      
      def get(path_info = '', &block); route('GET', path_info, &block) end
      def post(path_info = '', &block); route('POST', path_info, &block) end
      def put(path_info = '', &block); route('PUT', path_info, &block) end
      def head(path_info = '', &block); route('HEAD', path_info, &block) end
      def delete(path_info = '', &block); route('DELETE', path_info, &block) end
      
      def namespace(space = nil, &block)
        if space || block_given?
          settings_stack << {}
          set(:namespace, space.to_s) if space
          instance_eval &block
          settings_stack.pop
        else
          Rack::Mount::Utils.normalize_path(settings_stack.map{|s| s[:namespace]}.join('/'))
        end
      end
      
      alias_method :group, :namespace
      alias_method :resource, :namespace
      alias_method :resources, :namespace
      
      def inherited(subclass)
        subclass.reset!
      end
    end  
    
    reset! 
  end
end