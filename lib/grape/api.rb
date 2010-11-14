require 'rack/mount'
require 'rack/auth/basic'

module Grape
  class API
    module Helpers; end
    
    class << self
      attr_reader :route_set
      
      def reset!
        @settings = [{}]
        @route_set = Rack::Mount::RouteSet.new
        @prototype = nil
      end
      
      def call(env)
        puts "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
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
      
      def version(*new_versions, &block)
        new_versions.any? ? nest(block){ set(:version, new_versions) } : settings[:version]
      end
      
      def default_format(new_format = nil)
        new_format ? set(:default_format, new_format.to_sym) : settings[:default_format]
      end

      # Add helper methods that will be accessible from any
      # endpoint within this namespace (and child namespaces).
      #
      #    class ExampleAPI
      #      helpers do
      #        def current_user
      #          User.find_by_id(params[:token])
      #        end
      #      end
      #    end
      def helpers(&block)
        if block_given?
          m = settings_stack.last[:helpers] || Module.new
          m.class_eval &block
          set(:helpers, m)
        else
          m = Module.new
          settings_stack.each do |s|
            m.send :include, s[:helpers] if s[:helpers]
          end
          m
        end
      end
      
      def auth(type = nil, options = {}, &block)
        if type
          set(:auth, {:type => type.to_sym, :proc => block}.merge(options))
        else
          settings[:auth]
        end
      end
      
      # Add HTTP Basic authorization to the API.
      #
      # @param [Hash] options A hash of options.
      # @option options [String] :realm "API Authorization" The HTTP Basic realm.
      def http_basic(options = {}, &block)
        options[:realm] ||= "API Authorization"
        auth :http_basic, options, &block
      end
      
      def route_set
        @route_set ||= Rack::Mount::RouteSet.new
      end
      
      def compile_path(path)
        parts = []
        parts << prefix if prefix
        parts << ':version' if version
        parts << namespace if namespace
        parts << path
        Rack::Mount::Utils.normalize_path(parts.join('/'))
      end

      def route(method, path_info, &block)
        route_set.add_route(build_endpoint(&block), 
          :path_info => Rack::Mount::Strexp.compile(compile_path(path_info)), 
          :request_method => method
        )
      end
      
      def build_endpoint(&block)
        
        b = Rack::Builder.new
        b.use Grape::Middleware::Error
        b.use Rack::Auth::Basic, settings[:auth][:realm], &settings[:auth][:proc] if settings[:auth] && settings[:auth][:type] == :http_basic
        b.use Grape::Middleware::Prefixer, :prefix => prefix if prefix        
        b.use Grape::Middleware::Versioner, :versions => (version if version.is_a?(Array)) if version
        b.use Grape::Middleware::Formatter, :default_format => default_format || :json
        
        endpoint = Grape::Endpoint.generate(&block)
        endpoint.send :include, helpers
        b.run endpoint
        
        b.to_app
      end
      
      def get(path_info = '', &block); route('GET', path_info, &block) end
      def post(path_info = '', &block); route('POST', path_info, &block) end
      def put(path_info = '', &block); route('PUT', path_info, &block) end
      def head(path_info = '', &block); route('HEAD', path_info, &block) end
      def delete(path_info = '', &block); route('DELETE', path_info, &block) end
      
      def namespace(space = nil, &block)
        if space || block_given?
          nest(block) do
            set(:namespace, space.to_s) if space
          end
        else
          Rack::Mount::Utils.normalize_path(settings_stack.map{|s| s[:namespace]}.join('/'))
        end
      end
      
      # Execute first the provided block, then each of the
      # block passed in. Allows for simple 'before' setups
      # of settings stack pushes.
      def nest(*blocks, &block)
        blocks.reject!{|b| b.nil?}
        if blocks.any?
          settings_stack << {}
          instance_eval &block
          blocks.each{|b| instance_eval &b}
          settings_stack.pop
        else
          instance_eval &block
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