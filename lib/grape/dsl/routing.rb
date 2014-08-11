require 'active_support/concern'

module Grape
  module DSL
    module Routing
      extend ActiveSupport::Concern

      included do

      end

      module ClassMethods
        attr_reader :endpoints, :routes, :route_set

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

            raise Grape::Exceptions::MissingVendorOption.new if options[:using] == :header && !options.key?(:vendor)

            @versions = versions | args
            nest(block) do
              set(:version, args)
              set(:version_options, options)
            end
          end

          @versions.last unless @versions.nil?
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

        def mount(mounts)
          mounts = { mounts => '/' } unless mounts.respond_to?(:each_pair)
          mounts.each_pair do |app, path|
            if app.respond_to?(:inherit_settings, true)
              app_settings = settings.clone
              mount_path = Rack::Mount::Utils.normalize_path([settings[:mount_path], path].compact.join("/"))
              app_settings.set :mount_path, mount_path
              app.inherit_settings(app_settings)
            end
            endpoints << Grape::Endpoint.new(
                settings.clone,
                method: :any,
                path: path,
                app: app
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

        alias_method :group, :namespace
        alias_method :resource, :namespace
        alias_method :resources, :namespace
        alias_method :segment, :namespace

        # An array of API routes.
        def routes
          @routes ||= prepare_routes
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

        def versions
          @versions ||= []
        end
      end
    end
  end
end
