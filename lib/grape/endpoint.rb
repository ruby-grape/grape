module Grape
  # An Endpoint is the proxy scope in which all routing
  # blocks are executed. In other words, any methods
  # on the instance level of this class may be called
  # from inside a `get`, `post`, etc.
  class Endpoint
    attr_accessor :block, :source, :options, :settings
    attr_reader :env, :request

    class << self
      # @api private
      #
      # Create an UnboundMethod that is appropriate for executing an endpoint
      # route.
      #
      # The unbound method allows explicit calls to +return+ without raising a
      # +LocalJumpError+. The method will be removed, but a +Proc+ reference to
      # it will be returned. The returned +Proc+ expects a single argument: the
      # instance of +Endpoint+ to bind to the method during the call.
      #
      # @param [String, Symbol] method_name
      # @return [Proc]
      # @raise [NameError] an instance method with the same name already exists
      def generate_api_method(method_name, &block)
        if instance_methods.include?(method_name.to_sym) || instance_methods.include?(method_name.to_s)
          raise NameError.new("method #{method_name.inspect} already exists and cannot be used as an unbound method name")
        end
        define_method(method_name, &block)
        method = instance_method(method_name)
        remove_method(method_name)
        proc { |endpoint_instance| method.bind(endpoint_instance).call }
      end
    end

    def initialize(settings, options = {}, &block)
      require_option(options, :path)
      require_option(options, :method)

      @settings = settings
      @options = options

      @options[:path] = Array(options[:path])
      @options[:path] << '/' if options[:path].empty?

      @options[:method] = Array(options[:method])
      @options[:route_options] ||= {}

      if block_given?
        @source = block
        @block = self.class.generate_api_method(method_name, &block)
      end
    end

    def require_option(options, key)
      raise Grape::Exceptions::MissingOption.new(key) unless options.has_key?(key)
    end

    def method_name
      [options[:method],
       Namespace.joined_space(settings),
       settings.gather(:mount_path).join('/'),
       options[:path].join('/')
     ].join(" ")
    end

    def routes
      @routes ||= endpoints ? endpoints.collect(&:routes).flatten : prepare_routes
    end

    def mount_in(route_set)
      if endpoints
        endpoints.each { |e| e.mount_in(route_set) }
      else
        routes.each do |route|
          methods = [route.route_method]
          if !settings[:do_not_route_head] && route.route_method == "GET"
            methods << "HEAD"
          end
          methods.each do |method|
            route_set.add_route(self, {
              path_info: route.route_compiled,
              request_method: method,
            }, { route_info: route })
          end
        end
      end
    end

    def prepare_routes
      routes = []
      options[:method].each do |method|
        options[:path].each do |path|
          prepared_path = prepare_path(path)

          anchor = options[:route_options][:anchor]
          anchor = anchor.nil? ? true : anchor

          endpoint_requirements = options[:route_options][:requirements] || {}
          all_requirements = (settings.gather(:namespace).map(&:requirements) << endpoint_requirements)
          requirements = all_requirements.reduce({}) do |base_requirements, single_requirements|
            base_requirements.merge!(single_requirements)
          end

          path = compile_path(prepared_path, anchor && !options[:app], requirements)
          regex = Rack::Mount::RegexpWithNamedGroups.new(path)
          path_params = {}
          # named parameters in the api path
          named_params = regex.named_captures.map { |nc| nc[0] } - %w{ version format }
          named_params.each { |named_param| path_params[named_param] = "" }
          # route parameters declared via desc or appended to the api declaration
          route_params = (options[:route_options][:params] || {})
          path_params.merge!(route_params)
          request_method = (method.to_s.upcase unless method == :any)
          routes << Route.new(options[:route_options].clone.merge(
            prefix: settings[:root_prefix],
            version: settings[:version] ? settings[:version].join('|') : nil,
            namespace: namespace,
            method: request_method,
            path: prepared_path,
            params: path_params,
            compiled: path,
          )
          )
        end
      end
      routes
    end

    def prepare_path(path)
      Path.prepare(path, namespace, settings)
    end

    def namespace
      @namespace ||= Namespace.joined_space_path(settings)
    end

    def compile_path(prepared_path, anchor = true, requirements = {})
      endpoint_options = {}
      endpoint_options[:version] = /#{settings[:version].join('|')}/ if settings[:version]
      endpoint_options.merge!(requirements)
      Rack::Mount::Strexp.compile(prepared_path, endpoint_options, %w( / . ? ), anchor)
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      env['api.endpoint'] = self
      if options[:app]
        options[:app].call(env)
      else
        builder = build_middleware
        builder.run options[:app] || lambda { |arg| run(arg) }
        builder.call(env)
      end
    end

    # The parameters passed into the request as
    # well as parsed from URL segments.
    def params
      @params ||= @request.params
    end

    # A filtering method that will return a hash
    # consisting only of keys that have been declared by a
    # `params` statement.
    #
    # @param params [Hash] The initial hash to filter. Usually this will just be `params`
    # @param options [Hash] Can pass `:include_missing` and `:stringify` options.
    def declared(params, options = {}, declared_params = settings[:declared_params])
      options[:include_missing] = true unless options.key?(:include_missing)

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
    # @param status [Integer] the HTTP Status Code. Defaults to 403.
    def error!(message, status = 403)
      throw :error, message: message, status: status
    end

    # Redirect to a new url.
    #
    # @param url [String] The url to be redirect.
    # @param options [Hash] The options used when redirect.
    #                       :permanent, default true.
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

    # Retrieves all available request headers.
    def headers
      @headers ||= @request.headers
    end

    # Set response content-type
    def content_type(val)
      header('Content-Type', val)
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
      entity_class = options.delete(:with)

      # auto-detect the entity from the first object in the collection
      object_instance = object.respond_to?(:first) ? object.first : object

      object_instance.class.ancestors.each do |potential|
        entity_class ||= (settings[:representations] || {})[potential]
      end

      entity_class ||= object_instance.class.const_get(:Entity) if object_instance.class.const_defined?(:Entity)

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

    protected

    # Return the collection of endpoints within this endpoint.
    # This is the case when an Grape::API mounts another Grape::API.
    def endpoints
      if options[:app] && options[:app].respond_to?(:endpoints)
        options[:app].endpoints
      else
        nil
      end
    end

    def run(env)
      @env = env
      @header = {}
      @request = Grape::Request.new(@env)

      extend helpers
      cookies.read(@request)

      run_filters befores

      # Retieve validations from this namespace and all parent namespaces.
      validation_errors = []
      settings.gather(:validations).each do |validator|
        begin
          validator.validate!(params)
        rescue Grape::Exceptions::Validation => e
          validation_errors << e
        end
      end

      if validation_errors.any?
        raise Grape::Exceptions::ValidationErrors, errors: validation_errors
      end

      run_filters after_validations

      response_text = @block ? @block.call(self) : nil
      run_filters afters
      cookies.write(header)

      [status, header, [body || response_text]]
    end

    def build_middleware
      b = Rack::Builder.new

      b.use Rack::Head
      b.use Grape::Middleware::Error,
            format: settings[:format],
            default_status: settings[:default_error_status] || 403,
            rescue_all: settings[:rescue_all],
            rescued_errors: aggregate_setting(:rescued_errors),
            default_error_formatter: settings[:default_error_formatter],
            error_formatters: settings[:error_formatters],
            rescue_options: settings[:rescue_options],
            rescue_handlers: merged_setting(:rescue_handlers)

      aggregate_setting(:middleware).each do |m|
        m = m.dup
        block = m.pop if m.last.is_a?(Proc)
        if block
          b.use(*m, &block)
        else
          b.use(*m)
        end
      end

      b.use Rack::Auth::Basic, settings[:auth][:realm], &settings[:auth][:proc] if settings[:auth] && settings[:auth][:type] == :http_basic
      b.use Rack::Auth::Digest::MD5, settings[:auth][:realm], settings[:auth][:opaque], &settings[:auth][:proc] if settings[:auth] && settings[:auth][:type] == :http_digest

      if settings[:version]
        b.use Grape::Middleware::Versioner.using(settings[:version_options][:using]), {
          versions: settings[:version] ? settings[:version].flatten : nil,
          version_options: settings[:version_options],
          prefix: settings[:root_prefix]
        }
      end

      b.use Grape::Middleware::Formatter,
            format: settings[:format],
            default_format: settings[:default_format] || :txt,
            content_types: settings[:content_types],
            formatters: settings[:formatters],
            parsers: settings[:parsers]

      b
    end

    def helpers
      m = Module.new
      settings.stack.each do |frame|
        m.send :include, frame[:helpers] if frame[:helpers]
      end
      m
    end

    def aggregate_setting(key)
      settings.stack.inject([]) do |aggregate, frame|
        aggregate + (frame[key] || [])
      end
    end

    def merged_setting(key)
      settings.stack.inject({}) do |merged, frame|
        merged.merge(frame[key] || {})
      end
    end

    def run_filters(filters)
      (filters || []).each do |filter|
        instance_eval(&filter)
      end
    end

    def befores
      aggregate_setting(:befores)
    end

    def after_validations
      aggregate_setting(:after_validations)
    end

    def afters
      aggregate_setting(:afters)
    end
  end
end
