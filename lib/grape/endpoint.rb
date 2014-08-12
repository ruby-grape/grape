module Grape
  # An Endpoint is the proxy scope in which all routing
  # blocks are executed. In other words, any methods
  # on the instance level of this class may be called
  # from inside a `get`, `post`, etc.
  class Endpoint
    attr_accessor :block, :source, :options, :settings
    attr_reader :env, :request, :headers, :params

    include Grape::DSL::InsideRoute

    class << self
      def before_each(new_setup = false, &block)
        if new_setup == false
          if block_given?
            @before_each = block
          else
            return @before_each
          end
        else
          @before_each = new_setup
        end
      end

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
      @settings[:default_error_status] ||= 500

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
      raise Grape::Exceptions::MissingOption.new(key) unless options.key?(key)
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
                                  request_method: method
            },  route_info: route)
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
          named_params = regex.named_captures.map { |nc| nc[0] } - %w(version format)
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
            compiled: path
          ))
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
      extend helpers

      env['api.endpoint'] = self
      if options[:app]
        options[:app].call(env)
      else
        builder = build_middleware
        builder.run options[:app] || lambda { |arg| run(arg) }
        builder.call(env)
      end
    end

    # Return the collection of endpoints within this endpoint.
    # This is the case when an Grape::API mounts another Grape::API.
    def endpoints
      if options[:app] && options[:app].respond_to?(:endpoints)
        options[:app].endpoints
      else
        nil
      end
    end

    protected

    def run(env)
      @env = env
      @header = {}

      @request = Grape::Request.new(env)
      @params = @request.params
      @headers = @request.headers

      cookies.read(@request)

      self.class.before_each.call(self) if self.class.before_each

      run_filters befores

      run_filters before_validations

      # Retrieve validations from this namespace and all parent namespaces.
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
            content_types: settings[:content_types],
            default_status: settings[:default_error_status],
            rescue_all: settings[:rescue_all],
            default_error_formatter: settings[:default_error_formatter],
            error_formatters: settings[:error_formatters],
            rescue_options: settings[:rescue_options],
            rescue_handlers: merged_setting(:rescue_handlers),
            base_only_rescue_handlers: merged_setting(:base_only_rescue_handlers),
            all_rescue_handler: settings[:all_rescue_handler]

      aggregate_setting(:middleware).each do |m|
        m = m.dup
        block = m.pop if m.last.is_a?(Proc)
        if block
          b.use(*m, &block)
        else
          b.use(*m)
        end
      end

      if settings[:version]
        b.use Grape::Middleware::Versioner.using(settings[:version_options][:using]),
              versions: settings[:version] ? settings[:version].flatten : nil,
              version_options: settings[:version_options],
              prefix: settings[:root_prefix]

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

    def before_validations
      aggregate_setting(:before_validations)
    end

    def after_validations
      aggregate_setting(:after_validations)
    end

    def afters
      aggregate_setting(:afters)
    end
  end
end
