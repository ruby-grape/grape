require 'rack/mount'
require 'rack/auth/basic'
require 'rack/auth/digest/md5'
require 'logger'

module Grape
  # The API class is the primary entry point for
  # creating Grape APIs. Users should subclass this
  # class in order to build an API.
  class API
    class << self
      attr_reader :route_set
      attr_reader :versions
      attr_reader :routes
      
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
      
      # Define a root URL prefix for your entire
      # API.
      def prefix(prefix = nil)
        prefix ? set(:root_prefix, prefix) : settings[:root_prefix]
      end

      # Specify an API version.
      #
      # @example API with legacy support.
      #   class MyAPI < Grape::API
      #     version 'v2'
      #     
      #     get '/main' do
      #       {:some => 'data'}
      #     end
      #         
      #     version 'v1' do
      #       get '/main' do
      #         {:legacy => 'data'}
      #       end
      #     end
      #   end
      #
      def version(*new_versions, &block)
        if new_versions.any?
          @versions = versions | new_versions
          nest(block) { set(:version, new_versions) }
        else
          settings[:version]
        end
      end
      
      # Specify the default format for the API's 
      # serializers. Currently only `:json` is
      # supported.
      def default_format(new_format = nil)
        new_format ? set(:default_format, new_format.to_sym) : settings[:default_format]
      end

      # Specify the format for error messages.
      # May be `:json` or `:txt` (default).
      def error_format(new_format = nil)
        new_format ? set(:error_format, new_format.to_sym) : settings[:error_format]
      end

      # Specify the default status code for errors.
      def default_error_status(new_status = nil)
        new_status ? set(:default_error_status, new_status) : settings[:default_error_status]
      end

      # Allows you to rescue certain exceptions that occur to return
      # a grape error rather than raising all the way to the
      # server level.
      #
      # @example Rescue from custom exceptions
      #     class ExampleAPI < Grape::API
      #       class CustomError < StandardError; end
      #
      #       rescue_from CustomError
      #     end
      #
      # @overload rescue_from(*exception_classes, options = {})
      #   @param [Array] exception_classes A list of classes that you want to rescue, or
      #     the symbol :all to rescue from all exceptions.
      #   @param [Hash] options Options for the rescue usage.
      #   @option options [Boolean] :backtrace Include a backtrace in the rescue response.
      def rescue_from(*args)
        set(:rescue_options, args.pop) if args.last.is_a?(Hash)
        set(:rescue_all, true) and return if args.include?(:all)
        set(:rescued_errors, args)
      end

      # Add helper methods that will be accessible from any
      # endpoint within this namespace (and child namespaces).
      #
      # @example Define some helpers.
      #     class ExampleAPI < Grape::API
      #       helpers do
      #         def current_user
      #           User.find_by_id(params[:token])
      #         end
      #       end
      #     end
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
      # only `:http_basic`, `:http_digest` and `:oauth2` are supported.
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

      def http_digest(options = {}, &block)
        options[:realm] ||= "API Authorization"
        options[:opaque] ||= "secret"
        auth :http_digest, options, &block
      end
      
      # Defines a route that will be recognized
      # by the Grape API.
      #
      # @param methods [HTTP Verb] One or more HTTP verbs that are accepted by this route. Set to `:any` if you want any verb to be accepted.
      # @param paths [String] One or more strings representing the URL segment(s) for this route.
      #
      # @example Defining a basic route.
      #   class MyAPI < Grape::API
      #     route(:any, '/hello') do
      #       {:hello => 'world'}
      #     end
      #   end
      def route(methods, paths = ['/'], route_options = {}, &block)
        methods = Array(methods)
        
        paths = ['/'] if ! paths || paths == []
        paths = Array(paths)
        
        endpoint = build_endpoint(&block)        
        
        endpoint_options = {}
        endpoint_options[:version] = /#{version.join('|')}/ if version
        
        methods.each do |method|
          paths.each do |path|

            compiled_path = compile_path(path)
            path = Rack::Mount::Strexp.compile(compiled_path, endpoint_options, %w( / . ? ), true)
            request_method = (method.to_s.upcase unless method == :any)

            routes << Route.new({
              :prefix => prefix, 
              :version => version ? version.join('|') : nil, 
              :namespace => namespace, 
              :method => request_method, 
              :path => compiled_path}
              .merge(route_options || {}))

            route_set.add_route(endpoint, 
              :path_info => path, 
              :request_method => request_method
            )
          end
        end
      end
      
      def get(paths = ['/'], options = {}, &block); route('GET', paths, options, &block) end
      def post(paths = ['/'], options = {}, &block); route('POST', paths, options, &block) end
      def put(paths = ['/'], options = {}, &block); route('PUT', paths, options, &block) end
      def head(paths = ['/'], options = {}, &block); route('HEAD', paths, options, &block) end
      def delete(paths = ['/'], options = {}, &block); route('DELETE', paths, options, &block) end
      
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

      # Apply a custom middleware to the API. Applies
      # to the current namespace and any children, but
      # not parents.
      #
      # @param middleware_class [Class] The class of the middleware you'd like to inject.
      def use(middleware_class, *args)
        settings_stack.last[:middleware] ||= []
        settings_stack.last[:middleware] << [middleware_class, *args]        
      end

      # Retrieve an array of the middleware classes
      # and arguments that are currently applied to the
      # application.
      def middleware
        settings_stack.inject([]){|a,s| a += s[:middleware] if s[:middleware]; a}
      end

      # An array of API routes.
      def routes
        @routes ||= []
      end
      
      def versions
        @versions ||= []
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
        b.use Grape::Middleware::Error, 
          :default_status => settings[:default_error_status] || 403, 
          :rescue_all => settings[:rescue_all], 
          :rescued_errors => settings[:rescued_errors], 
          :format => settings[:error_format] || :txt, 
          :rescue_options => settings[:rescue_options]
        b.use Rack::Auth::Basic, settings[:auth][:realm], &settings[:auth][:proc] if settings[:auth] && settings[:auth][:type] == :http_basic
        b.use Rack::Auth::Digest::MD5, settings[:auth][:realm], settings[:auth][:opaque], &settings[:auth][:proc] if settings[:auth] && settings[:auth][:type] == :http_digest
        b.use Grape::Middleware::Prefixer, :prefix => prefix if prefix
        b.use Grape::Middleware::Versioner, :versions => (version if version.is_a?(Array)) if version
        b.use Grape::Middleware::Formatter, :default_format => default_format || :json
        middleware.each{|m| b.use *m }

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
        parts << namespace.to_s if namespace
        parts << path.to_s if path && '/' != path
        parts.last << '(.:format)'
        Rack::Mount::Utils.normalize_path(parts.join('/'))
      end
    end  
    
    reset! 
  end
end
