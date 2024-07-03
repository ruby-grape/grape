# frozen_string_literal: true

module Grape
  module DSL
    module InsideRoute
      extend ActiveSupport::Concern
      include Grape::DSL::Settings
      include Grape::DSL::Headers

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
        def declared(passed_params, options = {}, declared_params = nil, params_nested_path = [])
          options = options.reverse_merge(include_missing: true, include_parent_namespaces: true, evaluate_given: false)
          declared_params ||= optioned_declared_params(**options)

          res = if passed_params.is_a?(Array)
                  declared_array(passed_params, options, declared_params, params_nested_path)
                else
                  declared_hash(passed_params, options, declared_params, params_nested_path)
                end

          if (key_maps = namespace_stackable(:contract_key_map))
            key_maps.each { |key_map| key_map.write(passed_params, res) }
          end

          res
        end

        private

        def declared_array(passed_params, options, declared_params, params_nested_path)
          passed_params.map do |passed_param|
            declared(passed_param || {}, options, declared_params, params_nested_path)
          end
        end

        def declared_hash(passed_params, options, declared_params, params_nested_path)
          declared_params.each_with_object(passed_params.class.new) do |declared_param_attr, memo|
            next if options[:evaluate_given] && !declared_param_attr.scope.attr_meets_dependency?(passed_params)

            declared_hash_attr(passed_params, options, declared_param_attr.key, params_nested_path, memo)
          end
        end

        def declared_hash_attr(passed_params, options, declared_param, params_nested_path, memo)
          renamed_params = route_setting(:renamed_params) || {}
          if declared_param.is_a?(Hash)
            declared_param.each_pair do |declared_parent_param, declared_children_params|
              params_nested_path_dup = params_nested_path.dup
              params_nested_path_dup << declared_parent_param.to_s
              next unless options[:include_missing] || passed_params.key?(declared_parent_param)

              rename_path = params_nested_path + [declared_parent_param.to_s]
              renamed_param_name = renamed_params[rename_path]

              memo_key = optioned_param_key(renamed_param_name || declared_parent_param, options)
              passed_children_params = passed_params[declared_parent_param] || passed_params.class.new

              memo[memo_key] = handle_passed_param(params_nested_path_dup, passed_children_params.any?) do
                declared(passed_children_params, options, declared_children_params, params_nested_path_dup)
              end
            end
          else
            # If it is not a Hash then it does not have children.
            # Find its value or set it to nil.
            return unless options[:include_missing] || passed_params.key?(declared_param)

            rename_path = params_nested_path + [declared_param.to_s]
            renamed_param_name = renamed_params[rename_path]

            memo_key = optioned_param_key(renamed_param_name || declared_param, options)
            passed_param = passed_params[declared_param]

            params_nested_path_dup = params_nested_path.dup
            params_nested_path_dup << declared_param.to_s
            memo[memo_key] = passed_param || handle_passed_param(params_nested_path_dup) do
              passed_param
            end
          end
        end

        def handle_passed_param(params_nested_path, has_passed_children = false, &_block)
          return yield if has_passed_children

          key = params_nested_path[0]
          key += "[#{params_nested_path[1..].join('][')}]" if params_nested_path.size > 1

          route_options_params = options[:route_options][:params] || {}
          type = route_options_params.dig(key, :type)
          has_children = route_options_params.keys.any? { |k| k != key && k.start_with?("#{key}[") }

          if type == 'Hash' && !has_children
            {}
          elsif type == 'Array' || (type&.start_with?('[') && type&.exclude?(','))
            []
          elsif type == 'Set' || type&.start_with?('#<Set')
            Set.new
          else
            yield
          end
        end

        def optioned_param_key(declared_param, options)
          options[:stringify] ? declared_param.to_s : declared_param.to_sym
        end

        def optioned_declared_params(**options)
          declared_params = if options[:include_parent_namespaces]
                              # Declared params including parent namespaces
                              route_setting(:declared_params)
                            else
                              # Declared params at current namespace
                              namespace_stackable(:declared_params).last || []
                            end

          raise ArgumentError, 'Tried to filter for declared parameters but none exist.' unless declared_params

          declared_params
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
        raise MethodNotYetAvailable, '#declared is not available prior to parameter validation.'
      end

      # The API version as specified in the URL.
      def version
        env[Grape::Env::API_VERSION]
      end

      def configuration
        options[:for].configuration.evaluate
      end

      # End the request and display an error to the
      # end user with the specified message.
      #
      # @param message [String] The message to display.
      # @param status [Integer] The HTTP Status Code. Defaults to default_error_status, 500 if not set.
      # @param additional_headers [Hash] Addtional headers for the response.
      # @param backtrace [Array<String>] The backtrace of the exception that caused the error.
      # @param original_exception [Exception] The original exception that caused the error.
      def error!(message, status = nil, additional_headers = nil, backtrace = nil, original_exception = nil)
        status = self.status(status || namespace_inheritable(:default_error_status))
        headers = additional_headers.present? ? header.merge(additional_headers) : header
        throw :error, message: message, status: status, headers: headers, backtrace: backtrace, original_exception: original_exception
      end

      # Creates a Rack response based on the provided message, status, and headers.
      # The content type in the headers is set to the default content type unless provided.
      # The message is HTML-escaped if the content type is 'text/html'.
      #
      # @param message [String] The content of the response.
      # @param status [Integer] The HTTP status code.
      # @params headers [Hash] (optional) Headers for the response
      #                      (default: {Rack::CONTENT_TYPE => content_type}).
      #
      # Returns:
      # A Rack::Response object containing the specified message, status, and headers.
      #
      def rack_response(message, status = 200, headers = { Rack::CONTENT_TYPE => content_type })
        Grape.deprecator.warn('The rack_response method has been deprecated, use error! instead.')
        message = Rack::Utils.escape_html(message) if headers[Rack::CONTENT_TYPE] == 'text/html'
        Rack::Response.new(Array.wrap(message), Rack::Utils.status_code(status), headers)
      end

      # Redirect to a new url.
      #
      # @param url [String] The url to be redirect.
      # @param options [Hash] The options used when redirect.
      #                       :permanent, default false.
      #                       :body, default a short message including the URL.
      def redirect(url, permanent: false, body: nil, **_options)
        body_message = body
        if permanent
          status 301
          body_message ||= "This resource has been moved permanently to #{url}."
        elsif http_version == 'HTTP/1.1' && !request.get?
          status 303
          body_message ||= "An alternate resource is located at #{url}."
        else
          status 302
          body_message ||= "This resource has been moved temporarily to #{url}."
        end
        header Grape::Http::Headers::LOCATION, url
        content_type 'text/plain'
        body body_message
      end

      # Set or retrieve the HTTP status code.
      #
      # @param status [Integer] The HTTP Status Code to return for this request.
      def status(status = nil)
        case status
        when Symbol
          raise ArgumentError, "Status code :#{status} is invalid." unless Rack::Utils::SYMBOL_TO_STATUS_CODE.key?(status)

          @status = Rack::Utils.status_code(status)
        when Integer
          @status = status
        when nil
          return @status if instance_variable_defined?(:@status) && @status

          if request.post?
            201
          elsif request.delete?
            if instance_variable_defined?(:@body) && @body.present?
              200
            else
              204
            end
          else
            200
          end
        else
          raise ArgumentError, 'Status code must be Integer or Symbol.'
        end
      end

      # Set response content-type
      def content_type(val = nil)
        if val
          header(Rack::CONTENT_TYPE, val)
        else
          header[Rack::CONTENT_TYPE]
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
          instance_variable_defined?(:@body) ? @body : nil
        end
      end

      # Allows you to explicitly return no content.
      #
      # @example
      #   delete :id do
      #     return_no_content
      #     "not returned"
      #   end
      #
      #   DELETE /12 # => 204 No Content, ""
      def return_no_content
        status 204
        body false
      end

      # Deprecated method to send files to the client. Use `sendfile` or `stream`
      def file(value = nil)
        if value.is_a?(String)
          Grape.deprecator.warn('Use sendfile or stream to send files.')
          sendfile(value)
        elsif !value.is_a?(NilClass)
          Grape.deprecator.warn('Use stream to use a Stream object.')
          stream(value)
        else
          Grape.deprecator.warn('Use sendfile or stream to send files.')
          sendfile
        end
      end

      # Allows you to send a file to the client via sendfile.
      #
      # @example
      #   get '/file' do
      #     sendfile FileStreamer.new(...)
      #   end
      #
      #   GET /file # => "contents of file"
      def sendfile(value = nil)
        if value.is_a?(String)
          file_body = Grape::ServeStream::FileBody.new(value)
          @stream = Grape::ServeStream::StreamResponse.new(file_body)
        elsif !value.is_a?(NilClass)
          raise ArgumentError, 'Argument must be a file path'
        else
          stream
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
        return if value.nil? && @stream.nil?

        header Rack::CONTENT_LENGTH, nil
        header Grape::Http::Headers::TRANSFER_ENCODING, nil
        header Rack::CACHE_CONTROL, 'no-cache' # Skips ETag generation (reading the response up front)
        if value.is_a?(String)
          file_body = Grape::ServeStream::FileBody.new(value)
          @stream = Grape::ServeStream::StreamResponse.new(file_body)
        elsif value.respond_to?(:each)
          @stream = Grape::ServeStream::StreamResponse.new(value)
        elsif !value.is_a?(NilClass)
          raise ArgumentError, 'Stream object must respond to :each.'
        else
          @stream
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
                           entity_representation_for(entity_class, object, options)
                         else
                           object
                         end

        representation = { root => representation } if root

        if key
          representation = (body || {}).merge(key => representation)
        elsif entity_class.present? && body
          raise ArgumentError, "Representation of type #{representation.class} cannot be merged." unless representation.respond_to?(:merge)

          representation = body.merge(representation)
        end

        body representation
      end

      # Returns route information for the current request.
      #
      # @example
      #
      #   desc "Returns the route description."
      #   get '/' do
      #     route.description
      #   end
      def route
        env[Grape::Env::GRAPE_ROUTING_ARGS][:route_info]
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
          # entity class not explicitly defined, auto-detect from relation#klass or first object in the collection
          object_class = if object.respond_to?(:klass)
                           object.klass
                         else
                           object.respond_to?(:first) ? object.first.class : object.class
                         end

          object_class.ancestors.each do |potential|
            entity_class ||= (namespace_stackable_with_hash(:representations) || {})[potential]
          end

          entity_class ||= object_class.const_get(:Entity) if object_class.const_defined?(:Entity) && object_class.const_get(:Entity).respond_to?(:represent)
        end

        entity_class
      end

      # @return the representation of the given object as done through
      #   the given entity_class.
      def entity_representation_for(entity_class, object, options)
        embeds = { env: env }
        embeds[:version] = env[Grape::Env::API_VERSION] if env.key?(Grape::Env::API_VERSION)
        entity_class.represent(object, **embeds.merge(options))
      end

      def http_version
        env['HTTP_VERSION'] || env[Rack::SERVER_PROTOCOL]
      end

      def context
        self
      end
    end
  end
end
