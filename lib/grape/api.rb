module Grape
  # The API class is the primary entry point for
  # creating Grape APIs.Users should subclass this
  # class in order to build an API.
  class API
    extend Validations::ClassMethods

    class << self
      attr_reader :endpoints, :instance, :routes, :route_set, :settings, :versions
      attr_writer :logger

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
        @routes = nil
        reset_validations!
      end

      def compile
        @instance = new
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

      # Define a root URL prefix for your entire API.
      def prefix(prefix = nil)
        prefix ? set(:root_prefix, prefix) : settings[:root_prefix]
      end

      # Do not route HEAD requests to GET requests automatically
      def do_not_route_head!
        set(:do_not_route_head, true)
      end

      # Do not automatically route OPTIONS
      def do_not_route_options!
        set(:do_not_route_options, true)
      end

      # Specify an API version.
      #
      # @example API with legacy support.
      #   class MyAPI < Grape::API
      #     version 'v2'
      #
      #     get '/main' do
      #       {some: 'data'}
      #     end
      #
      #     version 'v1' do
      #       get '/main' do
      #         {legacy: 'data'}
      #       end
      #     end
      #   end
      #
      def version(*args, &block)
        if args.any?
          options = args.pop if args.last.is_a? Hash
          options ||= {}
          options = { using: :path }.merge(options)

          raise Grape::Exceptions::MissingVendorOption.new if options[:using] == :header && !options.has_key?(:vendor)

          @versions = versions | args
          nest(block) do
            set(:version, args)
            set(:version_options, options)
          end
        end

        @versions.last unless @versions.nil?
      end

      # Add a description to the next namespace or function.
      def desc(description, options = {})
        @last_description = options.merge(description: description)
      end

      # Specify the default format for the API's serializers.
      # May be `:json` or `:txt` (default).
      def default_format(new_format = nil)
        new_format ? set(:default_format, new_format.to_sym) : settings[:default_format]
      end

      # Specify the format for the API's serializers.
      # May be `:json`, `:xml`, `:txt`, etc.
      def format(new_format = nil)
        if new_format
          set(:format, new_format.to_sym)
          # define the default error formatters
          set(:default_error_formatter, Grape::ErrorFormatter::Base.formatter_for(new_format, {}))
          # define a single mime type
          mime_type = content_types[new_format.to_sym]
          raise Grape::Exceptions::MissingMimeType.new(new_format) unless mime_type
          settings.imbue(:content_types, new_format.to_sym => mime_type)
        else
          settings[:format]
        end
      end

      # Specify a custom formatter for a content-type.
      def formatter(content_type, new_formatter)
        settings.imbue(:formatters, content_type.to_sym => new_formatter)
      end

      # Specify a custom parser for a content-type.
      def parser(content_type, new_parser)
        settings.imbue(:parsers, content_type.to_sym => new_parser)
      end

      # Specify a default error formatter.
      def default_error_formatter(new_formatter_name = nil)
        if new_formatter_name
          new_formatter = Grape::ErrorFormatter::Base.formatter_for(new_formatter_name, {})
          set(:default_error_formatter, new_formatter)
        else
          settings[:default_error_formatter]
        end
      end

      def error_formatter(format, options)
        if options.is_a?(Hash) && options.has_key?(:with)
          formatter = options[:with]
        else
          formatter = options
        end

        settings.imbue(:error_formatters, format.to_sym => formatter)
      end

      # Specify additional content-types, e.g.:
      #   content_type :xls, 'application/vnd.ms-excel'
      def content_type(key, val)
        settings.imbue(:content_types, key.to_sym => val)
      end

      # All available content types.
      def content_types
        Grape::ContentTypes.content_types_for(settings[:content_types])
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
      #   @param [Proc] handler Execution proc to handle the given exception as an
      #     alternative to passing a block
      def rescue_from(*args, &block)
        if args.last.is_a?(Proc)
          handler = args.pop
        elsif block_given?
          handler = block
        end

        options = args.last.is_a?(Hash) ? args.pop : {}
        handler ||= proc { options[:with] } if options.has_key?(:with)

        if handler
          args.each do |arg|
            imbue(:rescue_handlers, { arg => handler })
          end
        end

        imbue(:rescue_options, options)

        if args.include?(:all)
          set(:rescue_all, true)
        else
          imbue(:rescued_errors, args)
        end
      end

      # Allows you to specify a default representation entity for a
      # class. This allows you to map your models to their respective
      # entities once and then simply call `present` with the model.
      #
      # @example
      #   class ExampleAPI < Grape::API
      #     represent User, with: Entity::User
      #
      #     get '/me' do
      #       present current_user # with: Entity::User is assumed
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
        raise Grape::Exceptions::InvalidWithOptionForRepresent.new unless options[:with] && options[:with].is_a?(Class)
        imbue(:representations, model_class => options[:with])
      end

      # Add helper methods that will be accessible from any
      # endpoint within this namespace (and child namespaces).
      #
      # When called without a block, all known helpers within this scope
      # are included.
      #
      # @param [Module] new_mod optional module of methods to include
      # @param [Block] block optional block of methods to include
      #
      # @example Define some helpers.
      #
      #     class ExampleAPI < Grape::API
      #       helpers do
      #         def current_user
      #           User.find_by_id(params[:token])
      #         end
      #       end
      #     end
      #
      def helpers(new_mod = nil, &block)
        if block_given? || new_mod
          mod = settings.peek[:helpers] || Module.new
          if new_mod
            mod.class_eval do
              include new_mod
            end
          end
          mod.class_eval(&block) if block_given?
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
          set(:auth, { type: type.to_sym, proc: block }.merge(options))
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
        mounts = { mounts => '/' } unless mounts.respond_to?(:each_pair)
        mounts.each_pair do |app, path|
          if app.respond_to?(:inherit_settings, true)
            app_settings = settings.clone
            mount_path = Rack::Mount::Utils.normalize_path([settings[:mount_path], path].compact.join("/"))
            app_settings.set :mount_path, mount_path
            app.inherit_settings(app_settings)
          end
          endpoints << Grape::Endpoint.new(settings.clone, {
            method: :any,
            path: path,
            app: app
          })
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
      #       {hello: 'world'}
      #     end
      #   end
      def route(methods, paths = ['/'], route_options = {}, &block)
        endpoint_options = {
          method: methods,
          path: paths,
          route_options: (@namespace_description || {}).deep_merge(@last_description || {}).deep_merge(route_options || {})
        }
        endpoints << Grape::Endpoint.new(settings.clone, endpoint_options, &block)

        @last_description = nil
        reset_validations!
      end

      def before(&block)
        imbue(:befores, [block])
      end

      def after_validation(&block)
        imbue(:after_validations, [block])
      end

      def after(&block)
        imbue(:afters, [block])
      end

      def get(paths = ['/'], options = {}, &block)
        route('GET', paths, options, &block)
      end

      def post(paths = ['/'], options = {}, &block)
        route('POST', paths, options, &block)
      end

      def put(paths = ['/'], options = {}, &block)
        route('PUT', paths, options, &block)
      end

      def head(paths = ['/'], options = {}, &block)
        route('HEAD', paths, options, &block)
      end

      def delete(paths = ['/'], options = {}, &block)
        route('DELETE', paths, options, &block)
      end

      def options(paths = ['/'], options = {}, &block)
        route('OPTIONS', paths, options, &block)
      end

      def patch(paths = ['/'], options = {}, &block)
        route('PATCH', paths, options, &block)
      end

      def namespace(space = nil, options = {},  &block)
        if space || block_given?
          previous_namespace_description = @namespace_description
          @namespace_description = (@namespace_description || {}).deep_merge(@last_description || {})
          @last_description = nil
          nest(block) do
            set(:namespace, Namespace.new(space, options)) if space
          end
          @namespace_description = previous_namespace_description
        else
          Namespace.joined_space_path(settings)
        end
      end

      # Thie method allows you to quickly define a parameter route segment
      # in your API.
      #
      # @param param [Symbol] The name of the parameter you wish to declare.
      # @option options [Regexp] You may supply a regular expression that the declared parameter must meet.
      def route_param(param, options = {}, &block)
        options = options.dup
        options[:requirements] = { param.to_sym => options[:requirements] } if options[:requirements].is_a?(Regexp)
        namespace(":#{param}", options, &block)
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
        settings.stack.inject([]) do |a, s|
          a += s[:middleware] if s[:middleware]
          a
        end
      end

      # An array of API routes.
      def routes
        @routes ||= prepare_routes
      end

      def versions
        @versions ||= []
      end

      def cascade(value = nil)
        if value.nil?
          settings.has_key?(:cascade) ? !!settings[:cascade] : true
        else
          set(:cascade, value)
        end
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
      self.class.endpoints.each do |endpoint|
        endpoint.mount_in(@route_set)
      end
      add_head_not_allowed_methods
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
      return !!self.class.settings[:cascade] if self.class.settings.has_key?(:cascade)
      return !!self.class.settings[:version_options][:cascade] if self.class.settings[:version_options] && self.class.settings[:version_options].has_key?(:cascade)
      true
    end

    reset!

    private

    # For every resource add a 'OPTIONS' route that returns an HTTP 204 response
    # with a list of HTTP methods that can be called. Also add a route that
    # will return an HTTP 405 response for any HTTP method that the resource
    # cannot handle.
    def add_head_not_allowed_methods
      allowed_methods = Hash.new { |h, k| h[k] = [] }
      resources = self.class.endpoints.map do |endpoint|
        if endpoint.options[:app] && endpoint.options[:app].respond_to?(:endpoints)
          endpoint.options[:app].endpoints.map(&:routes)
        else
          endpoint.routes
        end
      end
      resources.flatten.each do |route|
        allowed_methods[route.route_compiled] << route.route_method
      end
      allowed_methods.each do |path_info, methods|
        if methods.include?('GET') && !methods.include?("HEAD") && !self.class.settings[:do_not_route_head]
          methods = methods | ['HEAD']
        end
        allow_header = (["OPTIONS"] | methods).join(", ")
        unless methods.include?("OPTIONS") || self.class.settings[:do_not_route_options]
          @route_set.add_route(proc { [204, { 'Allow' => allow_header }, []] }, {
            path_info: path_info,
            request_method: "OPTIONS"
          })
        end
        not_allowed_methods = %w(GET PUT POST DELETE PATCH HEAD) - methods
        not_allowed_methods << "OPTIONS" if self.class.settings[:do_not_route_options]
        not_allowed_methods.each do |bad_method|
          @route_set.add_route(proc { [405, { 'Allow' => allow_header, 'Content-Type' => 'text/plain' }, []] }, {
            path_info: path_info,
            request_method: bad_method
          })
        end
      end
    end

  end
end
