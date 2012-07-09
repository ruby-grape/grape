require 'rack'
require 'grape'
require 'hashie'

module Grape
  # An Endpoint is the proxy scope in which all routing
  # blocks are executed. In other words, any methods
  # on the instance level of this class may be called
  # from inside a `get`, `post`, etc. block.
  class Endpoint
    attr_accessor :block, :options, :settings
    attr_reader :env, :request

    def initialize(settings, options = {}, &block)
      @settings = settings
      @block = block
      @options = options

      raise ArgumentError, "Must specify :path option." unless options.key?(:path)
      options[:path] = Array(options[:path])
      options[:path] = ['/'] if options[:path].empty?

      raise ArgumentError, "Must specify :method option." unless options.key?(:method)
      options[:method] = Array(options[:method])

      options[:route_options] ||= {}
    end

    def routes
      @routes ||= prepare_routes
    end

    def mount_in(route_set)
      if options[:app] && options[:app].respond_to?(:endpoints)
        options[:app].endpoints.each{|e| e.mount_in(route_set)}
      else
        routes.each do |route|
          route_set.add_route(self, {
            :path_info => route.route_compiled,
            :request_method => route.route_method,
          }, { :route_info => route })
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

          requirements = options[:route_options][:requirements] || {}

          path = compile_path(prepared_path, anchor && !options[:app], requirements)
          regex = Rack::Mount::RegexpWithNamedGroups.new(path)
          path_params = {}
          # named parameters in the api path
          named_params = regex.named_captures.map { |nc| nc[0] } - [ 'version', 'format' ]
          named_params.each { |named_param| path_params[named_param] = "" }
          # route parameters declared via desc or appended to the api declaration
          route_params = (options[:route_options][:params] || {})
          path_params.merge!(route_params)
          request_method = (method.to_s.upcase unless method == :any)
          route = Route.new(options[:route_options].clone.merge({
            :prefix => settings[:root_prefix],
            :version => settings[:version] ? settings[:version].join('|') : nil,
            :namespace => namespace,
            :method => request_method,
            :path => prepared_path,
            :params => path_params,
            :compiled => path,
            })
          )
          routes << route
        end
      end
      routes
    end

    def prepare_path(path)
      parts = []
      parts << settings[:root_prefix] if settings[:root_prefix]
      parts << ':version' if settings[:version] && settings[:version_options][:using] == :path
      parts << namespace.to_s if namespace
      parts << path.to_s if path && '/' != path
      Rack::Mount::Utils.normalize_path(parts.join('/') + '(.:format)')
    end

    def namespace
      Rack::Mount::Utils.normalize_path(settings.stack.map{|s| s[:namespace]}.join('/'))
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
        builder.run options[:app] || lambda{|env| self.run(env) }
        builder.call(env)
      end
    end

    # The parameters passed into the request as
    # well as parsed from URL segments.
    def params
      @params ||= Hashie::Mash.new.
        deep_merge(request.params).
        deep_merge(env['rack.routing_args'] || {}).
        deep_merge(self.body_params)
    end

    # Pull out request body params if the content type matches and we're on a POST or PUT
    def body_params
      if ['POST', 'PUT'].include?(request.request_method.to_s.upcase)
        return case env['CONTENT_TYPE']
          when 'application/json'
            MultiJson.decode(request.body.read)
          when 'application/xml'
            MultiXml.parse(request.body.read)
          else
            {}
          end
      end

      {}
    end

    # The API version as specified in the URL.
    def version; env['api.version'] end

    # End the request and display an error to the
    # end user with the specified message.
    #
    # @param message [String] The message to display.
    # @param status [Integer] the HTTP Status Code. Defaults to 403.
    def error!(message, status=403)
      throw :error, :message => message, :status => status
    end

    # Redirect to a new url.
    #
    # @param url [String] The url to be redirect.
    # @param options [Hash] The options used when redirect.
    #                       :permanent, default true.
    def redirect(url, options = {})
      merged_options = {:permanent => false }.merge(options)
      if merged_options[:permanent]
        status 304
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

    # Set or get a cookie
    #
    # @example
    #   cookies[:mycookie] = 'mycookie val'
    #   cookies['mycookie-string'] = 'mycookie string val'
    #   cookies[:more] = { :value => '123', :expires => Time.at(0) }
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
    #       :with => API::Entities::User,
    #       :admin => current_user.admin?
    #   end
    def present(object, options = {})
      entity_class = options.delete(:with)

      object.class.ancestors.each do |potential|
        entity_class ||= (settings[:representations] || {})[potential]
      end

      root = options.delete(:root)

      representation = if entity_class
        embeds = {:env => env}
        embeds[:version] = env['api.version'] if env['api.version']
        entity_class.represent(object, embeds.merge(options))
      else
        object
      end

      representation = { root => representation } if root
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

    def run(env)
      @env = env
      @header = {}
      @request = Rack::Request.new(@env)

      self.extend helpers
      cookies.read(@request)
      run_filters befores
      response_text = instance_eval &self.block
      run_filters afters
      cookies.write(header)
      
      [status, header, [body || response_text]]
    end

    def build_middleware
      b = Rack::Builder.new

      b.use Rack::Head
      b.use Grape::Middleware::Error,
        :default_status => settings[:default_error_status] || 403,
        :rescue_all => settings[:rescue_all],
        :rescued_errors => settings[:rescued_errors],
        :format => settings[:error_format] || :txt,
        :rescue_options => settings[:rescue_options],
        :rescue_handlers => settings[:rescue_handlers] || {}

      b.use Rack::Auth::Basic, settings[:auth][:realm], &settings[:auth][:proc] if settings[:auth] && settings[:auth][:type] == :http_basic
      b.use Rack::Auth::Digest::MD5, settings[:auth][:realm], settings[:auth][:opaque], &settings[:auth][:proc] if settings[:auth] && settings[:auth][:type] == :http_digest
      b.use Grape::Middleware::Prefixer, :prefix => settings[:root_prefix] if settings[:root_prefix]

      if settings[:version]
        b.use Grape::Middleware::Versioner.using(settings[:version_options][:using]), {
          :versions        => settings[:version],
          :version_options => settings[:version_options]
        }
      end
      
      b.use Grape::Middleware::Formatter,
        :format => settings[:format],
        :default_format => settings[:default_format] || :txt,
        :content_types => settings[:content_types]

      aggregate_setting(:middleware).each do |m|
        m = m.dup
        block = m.pop if m.last.is_a?(Proc)
        if block
          b.use *m, &block
        else
          b.use *m
        end
      end

      b
    end

    def helpers
      m = Module.new
      settings.stack.each{|frame| m.send :include, frame[:helpers] if frame[:helpers]}
      m
    end

    def aggregate_setting(key)
      settings.stack.inject([]) do |aggregate, frame|
        aggregate += (frame[key] || [])
      end
    end

    def run_filters(filters)
      (filters || []).each do |filter|
        instance_eval &filter
      end
    end

    def befores; aggregate_setting(:befores) end
    def afters; aggregate_setting(:afters) end
  end
end
