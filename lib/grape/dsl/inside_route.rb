require 'active_support/concern'

module Grape
  module DSL
    module InsideRoute
      extend ActiveSupport::Concern

      # A filtering method that will return a hash
      # consisting only of keys that have been declared by a
      # `params` statement against the current/target endpoint or parent
      # namespaces
      #
      # @param params [Hash] The initial hash to filter. Usually this will just be `params`
      # @param options [Hash] Can pass `:include_missing`, `:stringify` and `:include_parent_namespaces`
      # options. `:include_parent_namespaces` defaults to true, hence must be set to false if
      # you want only to return params declared against the current/target endpoint
      def declared(params, options = {}, declared_params = nil)
        options[:include_missing] = true unless options.key?(:include_missing)
        options[:include_parent_namespaces] = true unless options.key?(:include_parent_namespaces)
        if declared_params.nil?
          declared_params = !options[:include_parent_namespaces] ? settings[:declared_params] :
              settings.gather(:declared_params)
        end

        unless declared_params
          raise ArgumentError, "Tried to filter for declared parameters but none exist."
        end

        if params.is_a? Array
          params.map do |param|
            declared(param || {}, options, declared_params)
          end
        else
          declared_params.inject({}) do |hash, key|
            key = { key => nil } unless key.is_a? Hash

            key.each_pair do |parent, children|
              output_key = options[:stringify] ? parent.to_s : parent.to_sym
              if params.key?(parent) || options[:include_missing]
                hash[output_key] = if children
                                     declared(params[parent] || {}, options, Array(children))
                                   else
                                     params[parent]
                                   end
              end
            end

            hash
          end
        end
      end

      # The API version as specified in the URL.
      def version
        env['api.version']
      end

      # End the request and display an error to the
      # end user with the specified message.
      #
      # @param message [String] The message to display.
      # @param status [Integer] the HTTP Status Code. Defaults to default_error_status, 500 if not set.
      def error!(message, status = nil, headers = nil)
        self.status(status || settings[:default_error_status])
        throw :error, message: message, status: self.status, headers: headers
      end

      # Redirect to a new url.
      #
      # @param url [String] The url to be redirect.
      # @param options [Hash] The options used when redirect.
      #                       :permanent, default false.
      def redirect(url, options = {})
        merged_options = { permanent: false }.merge(options)
        if merged_options[:permanent]
          status 301
        else
          if env['HTTP_VERSION'] == 'HTTP/1.1' && request.request_method.to_s.upcase != "GET"
            status 303
          else
            status 302
          end
        end
        header "Location", url
        body ""
      end

      # Set or retrieve the HTTP status code.
      #
      # @param status [Integer] The HTTP Status Code to return for this request.
      def status(status = nil)
        if status
          @status = status
        else
          return @status if @status
          case request.request_method.to_s.upcase
          when 'POST'
            201
          else
            200
          end
        end
      end

      # Set an individual header or retrieve
      # all headers that have been set.
      def header(key = nil, val = nil)
        if key
          val ? @header[key.to_s] = val : @header.delete(key.to_s)
        else
          @header
        end
      end

      # Set response content-type
      def content_type(val = nil)
        if val
          header('Content-Type', val)
        else
          header['Content-Type']
        end
      end

      # Set or get a cookie
      #
      # @example
      #   cookies[:mycookie] = 'mycookie val'
      #   cookies['mycookie-string'] = 'mycookie string val'
      #   cookies[:more] = { value: '123', expires: Time.at(0) }
      #   cookies.delete :more
      #
      def cookies
        @cookies ||= Cookies.new
      end

      # Allows you to define the response body as something other than the
      # return value.
      #
      # @example
      #   get '/body' do
      #     body "Body"
      #     "Not the Body"
      #   end
      #
      #   GET /body # => "Body"
      def body(value = nil)
        if value
          @body = value
        else
          @body
        end
      end

      # Allows you to make use of Grape Entities by setting
      # the response body to the serializable hash of the
      # entity provided in the `:with` option. This has the
      # added benefit of automatically passing along environment
      # and version information to the serialization, making it
      # very easy to do conditional exposures. See Entity docs
      # for more info.
      #
      # @example
      #
      #   get '/users/:id' do
      #     present User.find(params[:id]),
      #       with: API::Entities::User,
      #       admin: current_user.admin?
      #   end
      def present(*args)
        options = args.count > 1 ? args.extract_options! : {}
        key, object = if args.count == 2 && args.first.is_a?(Symbol)
                        args
                      else
                        [nil, args.first]
                      end
        entity_class = entity_class_for_obj(object, options)

        root = options.delete(:root)

        representation = if entity_class
                           embeds = { env: env }
                           embeds[:version] = env['api.version'] if env['api.version']
                           entity_class.represent(object, embeds.merge(options))
                         else
                           object
                         end

        representation = { root => representation } if root
        representation = (@body || {}).merge(key => representation) if key
        body representation
      end

      # Returns route information for the current request.
      #
      # @example
      #
      #   desc "Returns the route description."
      #   get '/' do
      #     route.route_description
      #   end
      def route
        env["rack.routing_args"][:route_info]
      end

      def entity_class_for_obj(object, options)
        entity_class = options.delete(:with)

        if entity_class.nil?
          # entity class not explicitely defined, auto-detect from relation#klass or first object in the collection
          object_class = if object.respond_to?(:klass)
                           object.klass
                         else
                           object.respond_to?(:first) ? object.first.class : object.class
                         end

          object_class.ancestors.each do |potential|
            entity_class ||= (settings[:representations] || {})[potential]
          end

          entity_class ||= object_class.const_get(:Entity) if object_class.const_defined?(:Entity) && object_class.const_get(:Entity).respond_to?(:represent)
        end

        entity_class
      end
    end
  end
end
