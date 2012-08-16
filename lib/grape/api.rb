require 'rack/mount'
require 'rack/auth/basic'
require 'rack/auth/digest/md5'
require 'logger'
require 'grape/util/deep_merge'

module Grape
  # The API class is the primary entry point for
  # creating Grape APIs.Users should subclass this
  # class in order to build an API.
  class API
    extend Validations::ClassMethods
    
    class << self
      attr_reader :route_set
      attr_reader :versions
      attr_reader :routes
      attr_reader :settings
      attr_writer :logger
      attr_reader :endpoints
      attr_reader :mountings
      attr_reader :instance

      def logger(logger = nil)
        if logger
          @logger = logger
        else
          @logger ||= Logger.new($stdout)
        end
      end
      
      def reset!
        @settings  = Grape::Util::HashStack.new
        @route_set = Rack::Mount::RouteSet.new
        @endpoints = []
        @mountings = []
        @routes = nil
        reset_validations!
      end

      def compile
        @instance = self.new
      end

      def change!
        @instance = nil
      end

      def call(env)
        compile unless instance
        call!(env)
      end

      def call!(env)
        instance.call(env)
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
      def version(*args, &block)
        if args.any?
          options = args.pop if args.last.is_a? Hash
          options ||= {}
          options = {:using => :path}.merge!(options)
          @versions = versions | args
          nest(block) do
            set(:version, args)
            set(:version_options, options)
          end
        end
      end

      # Add a description to the next namespace or function.
      def desc(description, options = {})
        @last_description = options.merge(:description => description)
      end

      # Specify the default format for the API's serializers.
      # May be `:json` or `:txt` (default).
      def default_format(new_format = nil)
        new_format ? set(:default_format, new_format.to_sym) : settings[:default_format]
      end

      # Specify the format for the API's serializers.
      # May be `:json` or `:txt`.
      def format(new_format = nil)
        new_format ? set(:format, new_format.to_sym) : settings[:format]
      end
      
      # Specify the format for error messages.
      # May be `:json` or `:txt` (default).
      def error_format(new_format = nil)
        new_format ? set(:error_format, new_format.to_sym) : settings[:error_format]
      end

      # Specify additional content-types, e.g.:
      #   content_type :xls, 'application/vnd.ms-excel'
      def content_type(key, val)
        settings.imbue(:content_types, key.to_sym => val)
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
      #   @param [Block] block Execution block to handle the given exception.
      #   @param [Hash] options Options for the rescue usage.
      #   @option options [Boolean] :backtrace Include a backtrace in the rescue response.
      def rescue_from(*args, &block)
        if block_given?
          args.each do |arg|
            imbue(:rescue_handlers, { arg => block })
          end
        end
        imbue(:rescue_options, args.pop) if args.last.is_a?(Hash)
        set(:rescue_all, true) and return if args.include?(:all)
        imbue(:rescued_errors, args)
      end

      # Allows you to specify a default representation entity for a
      # class. This allows you to map your models to their respective
      # entities once and then simply call `present` with the model.
      #
      # @example
      #   class ExampleAPI < Grape::API
      #     represent User, :with => Entity::User
      #
      #     get '/me' do
      #       present current_user # :with => Entity::User is assumed
      #     end
      #   end
      #
      # Note that Grape will automatically go up the class ancestry to
      # try to find a representing entity, so if you, for example, define
      # an entity to represent `Object` then all presented objects will
      # bubble up and utilize the entity provided on that `represent` call.
      #
      # @param model_class [Class] The model class that will be represented.
      # @option options [Class] :with The entity class that will represent the model.
      def represent(model_class, options)
        raise ArgumentError, "You must specify an entity class in the :with option." unless options[:with] && options[:with].is_a?(Class)
        imbue(:representations, model_class => options[:with])
      end

      # Add helper methods that will be accessible from any
      # endpoint within this namespace (and child namespaces).
      #
      # When called without a block, all known helpers within this scope
      # are included.
      #
      # @param mod [Module] optional module of methods to include
      # @param &block [Block] optional block of methods to include
      #
      # @example Define some helpers.
      #     class ExampleAPI < Grape::API
      #       helpers do
      #         def current_user
      #           User.find_by_id(params[:token])
      #         end
      #       end
      #     end
      def helpers(new_mod = nil, &block)
        if block_given? || new_mod
          mod = settings.peek[:helpers] || Module.new
          if new_mod
            mod.class_eval do
              include new_mod
            end
          end
          mod.class_eval &block if block_given?
          set(:helpers, mod)
        else
          mod = Module.new
          settings.stack.each do |s|
            mod.send :include, s[:helpers] if s[:helpers]
          end
          change!
          mod
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

      def mount(mounts)
        mounts = {mounts => '/'} unless mounts.respond_to?(:each_pair)
        mounts.each_pair do |app, path|
          if app.respond_to?(:inherit_settings)
            app.inherit_settings(settings.clone)
          end

          endpoints << Grape::Endpoint.new(settings.clone,
            :method => :any,
            :path => path,
            :app => app
          )
        end
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
        endpoint_options = {
          :method => methods,
          :path => paths,
          :route_options => (@namespace_description || {}).deep_merge(@last_description || {}).deep_merge(route_options || {})
        }
        endpoints << Grape::Endpoint.new(settings.clone, endpoint_options, &block)
        
        @last_description = nil
        reset_validations!
      end

      def before(&block)
        imbue(:befores, [block])
      end

      def after(&block)
        imbue(:afters, [block])
      end

      def get(paths = ['/'], options = {}, &block); route('GET', paths, options, &block) end
      def post(paths = ['/'], options = {}, &block); route('POST', paths, options, &block) end
      def put(paths = ['/'], options = {}, &block); route('PUT', paths, options, &block) end
      def head(paths = ['/'], options = {}, &block); route('HEAD', paths, options, &block) end
      def delete(paths = ['/'], options = {}, &block); route('DELETE', paths, options, &block) end
      def options(paths = ['/'], options = {}, &block); route('OPTIONS', paths, options, &block) end
      def patch(paths = ['/'], options = {}, &block); route('PATCH', paths, options, &block) end

      def namespace(space = nil, &block)
        if space || block_given?
          previous_namespace_description = @namespace_description
          @namespace_description = (@namespace_description || {}).deep_merge(@last_description || {})
          @last_description = nil
          nest(block) do
            set(:namespace, space.to_s) if space
          end
          @namespace_description = previous_namespace_description
        else
          Rack::Mount::Utils.normalize_path(settings.stack.map{|s| s[:namespace]}.join('/'))
        end
      end

      alias_method :group, :namespace
      alias_method :resource, :namespace
      alias_method :resources, :namespace
      alias_method :segment, :namespace

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
      # @param middleware_class [Class] The class of the middleware you'd like
      #   to inject.
      def use(middleware_class, *args, &block)
        arr = [middleware_class, *args]
        arr << block if block_given?
        imbue(:middleware, [arr])
      end

      # Retrieve an array of the middleware classes
      # and arguments that are currently applied to the
      # application.
      def middleware
        settings.stack.inject([]){|a,s| a += s[:middleware] if s[:middleware]; a}
      end

      # An array of API routes.
      def routes
        @routes ||= prepare_routes
      end

      def versions
        @versions ||= []
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
        blocks.reject!{|b| b.nil?}
        if blocks.any?
          settings.push  # create a new context to eval the follow
          instance_eval &block if block_given?
          blocks.each{|b| instance_eval &b}
          settings.pop   # when finished, we pop the context
          reset_validations!
        else
          instance_eval &block
        end
      end

     def inherited(subclass)
        subclass.reset!
        subclass.logger = logger.clone
      end

      def inherit_settings(other_stack)
        settings.prepend other_stack
        endpoints.each{|e| e.settings.prepend(other_stack)}
      end
    end

    def initialize
      @route_set = Rack::Mount::RouteSet.new
      self.class.endpoints.each do |endpoint|
        endpoint.mount_in(@route_set)
      end
      @route_set.freeze
    end

    def call(env)
      @route_set.call(env)
    end

    reset!
  end
end
