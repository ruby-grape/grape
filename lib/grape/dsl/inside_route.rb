require 'active_support/concern'

module Grape
  module DSL
    module InsideRoute
      extend ActiveSupport::Concern
      include Grape::DSL::Settings

      # Denotes a situation where a DSL method has been invoked in a
      # filter which it should not yet be available in
      class MethodNotYetAvailable < StandardError; end

      # @param type [Symbol] The type of filter for which evaluation has been
      #   completed
      # @return [Module] A module containing method overrides suitable for the
      #   position in the filter evaluation sequence denoted by +type+.  This
      #   defaults to an empty module if no overrides are defined for the given
      #   filter +type+.
      def self.post_filter_methods(type)
        @post_filter_modules ||= { before: PostBeforeFilter }
        @post_filter_modules[type]
      end

      # Methods which should not be available in filters until the before filter
      # has completed
      module PostBeforeFilter
        def declared(params, options = {}, declared_params = nil)
          options = options.reverse_merge(include_missing: true, include_parent_namespaces: true)

          declared_params ||= (!options[:include_parent_namespaces] ? route_setting(:declared_params) : (route_setting(:saved_declared_params) || [])).flatten(1) || []

          fail ArgumentError, 'Tried to filter for declared parameters but none exist.' unless declared_params

          if params.is_a? Array
            params.map do |param|
              declared(param || {}, options, declared_params)
            end
          else
            declared_params.each_with_object(Hashie::Mash.new) do |key, hash|
              key = { key => nil } unless key.is_a? Hash

              key.each_pair do |parent, children|
                output_key = options[:stringify] ? parent.to_s : parent.to_sym

                next unless options[:include_missing] || params.key?(parent)

                hash[output_key] = if children
                                     children_params = params[parent] || (children.is_a?(Array) ? [] : {})
                                     declared(children_params, options, Array(children))
                                   else
                                     params[parent]
                                   end
              end
            end
          end
        end
      end

      # A filtering method that will return a hash
      # consisting only of keys that have been declared by a
      # `params` statement against the current/target endpoint or parent
      # namespaces.
      #
      # @see +PostBeforeFilter#declared+
      #
      # @param params [Hash] The initial hash to filter. Usually this will just be `params`
      # @param options [Hash] Can pass `:include_missing`, `:stringify` and `:include_parent_namespaces`
      # options. `:include_parent_namespaces` defaults to true, hence must be set to false if
      # you want only to return params declared against the current/target endpoint.
      def declared(*)
        fail MethodNotYetAvailable, '#declared is not available prior to parameter validation.'
      end

      # The API version as specified in the URL.
      def version
        env[Grape::Env::API_VERSION]
      end

      # End the request and display an error to the
      # end user with the specified message.
      #
      # @param message [String] The message to display.
      # @param status [Integer] the HTTP Status Code. Defaults to default_error_status, 500 if not set.
      def error!(message, status = nil, headers = nil)
        self.status(status || namespace_inheritable(:default_error_status))
        throw :error, message: message, status: self.status, headers: headers
      end

      # Redirect to a new url.
      #
      # @param url [String] The url to be redirect.
      # @param options [Hash] The options used when redirect.
      #                       :permanent, default false.
      #                       :body, default a short message including the URL.
      def redirect(url, options = {})
        permanent = options.fetch(:permanent, false)
        body_message = options.fetch(:body, nil)
        if permanent
          status 301
          body_message ||= "This resource has been moved permanently to #{url}."
        else
          if env[Grape::Http::Headers::HTTP_VERSION] == 'HTTP/1.1' && request.request_method.to_s.upcase != Grape::Http::Headers::GET
            status 303
            body_message ||= "An alternate resource is located at #{url}."
          else
            status 302
            body_message ||= "This resource has been moved temporarily to #{url}."
          end
        end
        header 'Location', url
        content_type 'text/plain'
        body body_message
      end

      # Set or retrieve the HTTP status code.
      #
      # @param status [Integer] The HTTP Status Code to return for this request.
      def status(status = nil)
        case status
        when Symbol
          if Rack::Utils::SYMBOL_TO_STATUS_CODE.keys.include?(status)
            @status = Rack::Utils.status_code(status)
          else
            fail ArgumentError, "Status code :#{status} is invalid."
          end
        when Fixnum
          @status = status
        when nil
          return @status if @status
          case request.request_method.to_s.upcase
          when Grape::Http::Headers::POST
            201
          else
            200
          end
        else
          fail ArgumentError, 'Status code must be Fixnum or Symbol.'
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
          header(Grape::Http::Headers::CONTENT_TYPE, val)
        else
          header[Grape::Http::Headers::CONTENT_TYPE]
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
        elsif value == false
          @body = ''
          status 204
        else
          @body
        end
      end

      # Allows you to define the response as a file-like object.
      #
      # @example
      #   get '/file' do
      #     file FileStreamer.new(...)
      #   end
      #
      #   GET /file # => "contents of file"
      def file(value = nil)
        if value
          @file = Grape::Util::FileResponse.new(value)
        else
          @file
        end
      end

      # Allows you to define the response as a streamable object.
      #
      # If Content-Length and Transfer-Encoding are blank (among other conditions),
      # Rack assumes this response can be streamed in chunks.
      #
      # @example
      #   get '/stream' do
      #     stream FileStreamer.new(...)
      #   end
      #
      #   GET /stream # => "chunked contents of file"
      #
      # See:
      # * https://github.com/rack/rack/blob/99293fa13d86cd48021630fcc4bd5acc9de5bdc3/lib/rack/chunked.rb
      # * https://github.com/rack/rack/blob/99293fa13d86cd48021630fcc4bd5acc9de5bdc3/lib/rack/etag.rb
      def stream(value = nil)
        header 'Content-Length', nil
        header 'Transfer-Encoding', nil
        header 'Cache-Control', 'no-cache' # Skips ETag generation (reading the response up front)
        file(value)
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
                           entity_representation_for(entity_class, object, options)
                         else
                           object
                         end

        representation = { root => representation } if root
        if key
          representation = (@body || {}).merge(key => representation)
        elsif entity_class.present? && @body
          fail ArgumentError, "Representation of type #{representation.class} cannot be merged." unless representation.respond_to?(:merge)
          representation = @body.merge(representation)
        end

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
        env[Grape::Env::RACK_ROUTING_ARGS][:route_info]
      end

      # Attempt to locate the Entity class for a given object, if not given
      # explicitly. This is done by looking for the presence of Klass::Entity,
      # where Klass is the class of the `object` parameter, or one of its
      # ancestors.
      # @param object [Object] the object to locate the Entity class for
      # @param options [Hash]
      # @option options :with [Class] the explicit entity class to use
      # @return [Class] the located Entity class, or nil if none is found
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
            entity_class ||= (Grape::DSL::Configuration.stacked_hash_to_hash(namespace_stackable(:representations)) || {})[potential]
          end

          entity_class ||= object_class.const_get(:Entity) if object_class.const_defined?(:Entity) && object_class.const_get(:Entity).respond_to?(:represent)
        end

        entity_class
      end

      # @return the representation of the given object as done through
      #   the given entity_class.
      def entity_representation_for(entity_class, object, options)
        embeds = { env: env }
        embeds[:version] = env[Grape::Env::API_VERSION] if env[Grape::Env::API_VERSION]
        entity_class.represent(object, embeds.merge(options))
      end
    end
  end
end
