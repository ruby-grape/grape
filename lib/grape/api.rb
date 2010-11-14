require 'rack/mount'
require 'rack/auth/basic'
require 'logger'

module Grape
  # The API class is the primary entry point for
  # creating Grape APIs. Users should subclass this
  # class in order to build an API.
  class API
    class << self
      attr_reader :route_set
      
      def logger
        @logger ||= Logger.new($STDOUT)
      end
      
      def reset!
        @settings = [{}]
        @route_set = Rack::Mount::RouteSet.new
        @prototype = nil
      end
      
      def call(env)
        logger.info "#{env['REQUEST_METHOD']} #{env['PATH_INFO']}"
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
      
      # Set a configuration value for this
      # namespace.
      #
      # @param key [Symbol] The key of the configuration variable.
      # @param value [Object] The value to which to set the configuration variable.
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
      
      # Specify the default format for the API's 
      # serializers. Currently only `:json` is
      # supported.
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
      
      # Add an authentication type to the API. Currently
      # only `:http_basic` is supported.
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
      
      # Defines a route that will be recognized
      # by the Grape API.
      #
      # @param methods [HTTP Verb(s)] One or more HTTP verbs that are accepted by this route. Set to `:any` if you want any verb to be accepted.
      # @param paths [String(s)] One or more strings representing the URL segment(s) for this route.
      # @param block [Proc] The code to be executed 
      def route(methods, paths, &block)
        methods = Array(methods)
        paths = ['/'] if paths == []
        paths = Array(paths)
        endpoint = build_endpoint(&block)
        
        methods.each do |method|
          paths.each do |path|
            path = Rack::Mount::Strexp.compile(compile_path(path))
            route_set.add_route(endpoint, 
              :path_info => path, 
              :request_method => (method.to_s.upcase unless method == :any)
            )
          end
        end
      end
      
      def get(*paths, &block); route('GET', paths, &block) end
      def post(*paths, &block); route('POST', paths, &block) end
      def put(*paths, &block); route('PUT', paths, &block) end
      def head(*paths, &block); route('HEAD', paths, &block) end
      def delete(*paths, &block); route('DELETE', paths, &block) end
      
      def namespace(space = nil, &block)
        if space || block_given?
          nest(block) do
            set(:namespace, space.to_s) if space
          end
        else
          Rack::Mount::Utils.normalize_path(settings_stack.map{|s| s[:namespace]}.join('/'))
        end
      end
      
      alias_method :group, :namespace
      alias_method :resource, :namespace
      alias_method :resources, :namespace
      
      # Create a scope without affecting the URL.
      # 
      # @param name [Symbol] Purely placebo, just allows to to name the scope to make the code more readable.
      def scope(name = nil, &block)
        nest(block)
      end
      
      protected
      
      # Execute first the provided block, then each of the
      # block passed in. Allows for simple 'before' setups
      # of settings stack pushes.
      def nest(*blocks, &block)
        blocks.reject!{|b| b.nil?}
        if blocks.any?
          settings_stack << {}
          instance_eval &block if block_given?
          blocks.each{|b| instance_eval &b}
          settings_stack.pop
        else
          instance_eval &block
        end
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
      
      def inherited(subclass)
        subclass.reset!
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
    end  
    
    reset! 
  end
end