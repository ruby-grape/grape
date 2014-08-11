module Grape
  # The API class is the primary entry point for
  # creating Grape APIs.Users should subclass this
  # class in order to build an API.
  class API
    extend Grape::Middleware::Auth::DSL

    include Grape::DSL::Validations
    include Grape::DSL::Callbacks
    include Grape::DSL::Configuration
    include Grape::DSL::Helpers
    include Grape::DSL::Middleware
    include Grape::DSL::RequestResponse
    include Grape::DSL::Routing

    class << self
      attr_reader :instance

      LOCK = Mutex.new

      def reset!
        @settings  = Grape::Util::HashStack.new
        @route_set = Rack::Mount::RouteSet.new
        @endpoints = []
        @routes = nil
        reset_validations!
      end

      def compile
        @instance ||= new
      end

      def change!
        @instance = nil
      end

      def call(env)
        LOCK.synchronize { compile } unless instance
        call!(env)
      end

      def call!(env)
        instance.call(env)
      end

      # Create a scope without affecting the URL.
      #
      # @param name [Symbol] Purely placebo, just allows to to name the scope to make the code more readable.
      def scope(name = nil, &block)
        nest(block)
      end

      def cascade(value = nil)
        if value.nil?
          settings.key?(:cascade) ? !!settings[:cascade] : true
        else
          set(:cascade, value)
        end
      end

      # Set a configuration value for this namespace.
      #
      # @param key [Symbol] The key of the configuration variable.
      # @param value [Object] The value to which to set the configuration variable.
      def set(key, value)
        settings[key.to_sym] = value
      end

      # Add to a configuration value for this
      # namespace.
      #
      # @param key [Symbol] The key of the configuration variable.
      # @param value [Object] The value to which to set the configuration variable.
      def imbue(key, value)
        settings.imbue(key, value)
      end

      protected

      def prepare_routes
        routes = []
        endpoints.each do |endpoint|
          routes.concat(endpoint.routes)
        end
        routes
      end

      # Execute first the provided block, then each of the
      # block passed in. Allows for simple 'before' setups
      # of settings stack pushes.
      def nest(*blocks, &block)
        blocks.reject! { |b| b.nil? }
        if blocks.any?
          settings.push  # create a new context to eval the follow
          instance_eval(&block) if block_given?
          blocks.each { |b| instance_eval(&b) }
          settings.pop # when finished, we pop the context
          reset_validations!
        else
          instance_eval(&block)
        end
      end

      def inherited(subclass)
        subclass.reset!
        subclass.logger = logger.clone
      end

      def inherit_settings(other_stack)
        settings.prepend other_stack
        endpoints.each do |e|
          e.settings.prepend(other_stack)
          e.options[:app].inherit_settings(other_stack) if e.options[:app].respond_to?(:inherit_settings, true)
        end
      end
    end

    def initialize
      @route_set = Rack::Mount::RouteSet.new
      add_head_not_allowed_methods_and_options_methods
      self.class.endpoints.each do |endpoint|
        endpoint.mount_in(@route_set)
      end
      @route_set.freeze
    end

    def call(env)
      status, headers, body = @route_set.call(env)
      headers.delete('X-Cascade') unless cascade?
      [status, headers, body]
    end

    # Some requests may return a HTTP 404 error if grape cannot find a matching
    # route. In this case, Rack::Mount adds a X-Cascade header to the response
    # and sets it to 'pass', indicating to grape's parents they should keep
    # looking for a matching route on other resources.
    #
    # In some applications (e.g. mounting grape on rails), one might need to trap
    # errors from reaching upstream. This is effectivelly done by unsetting
    # X-Cascade. Default :cascade is true.
    def cascade?
      return !!self.class.settings[:cascade] if self.class.settings.key?(:cascade)
      return !!self.class.settings[:version_options][:cascade] if self.class.settings[:version_options] && self.class.settings[:version_options].key?(:cascade)
      true
    end

    reset!

    private

    # For every resource add a 'OPTIONS' route that returns an HTTP 204 response
    # with a list of HTTP methods that can be called. Also add a route that
    # will return an HTTP 405 response for any HTTP method that the resource
    # cannot handle.
    def add_head_not_allowed_methods_and_options_methods
      methods_per_path = {}
      self.class.endpoints.each do |endpoint|
        routes = endpoint.routes
        routes.each do |route|
          methods_per_path[route.route_path] ||= []
          methods_per_path[route.route_path] << route.route_method
        end
      end

      # The paths we collected are prepared (cf. Path#prepare), so they
      # contain already versioning information when using path versioning.
      # Disable versioning so adding a route won't prepend versioning
      # informations again.
      without_versioning do
        methods_per_path.each do |path, methods|
          allowed_methods = methods.dup
          unless self.class.settings[:do_not_route_head]
            allowed_methods |= ['HEAD'] if allowed_methods.include?('GET')
          end

          allow_header = (['OPTIONS'] | allowed_methods).join(', ')
          unless self.class.settings[:do_not_route_options]
            unless allowed_methods.include?('OPTIONS')
              self.class.options(path, {}) do
                header 'Allow', allow_header
                status 204
                ''
              end
            end
          end

          not_allowed_methods = %w(GET PUT POST DELETE PATCH HEAD) - allowed_methods
          not_allowed_methods << 'OPTIONS' if self.class.settings[:do_not_route_options]
          self.class.route(not_allowed_methods, path) do
            header 'Allow', allow_header
            status 405
            ''
          end
        end
      end
    end

    def without_versioning(&block)
      self.class.settings.push(version: nil, version_options: nil)
      yield
      self.class.settings.pop
    end
  end
end
