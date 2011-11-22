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
    end

    def call(env)
      dup.call!(env)
    end

    def call!(env)
      builder = build_middleware
      builder.run lambda{|env| self.run(env) }
      builder.call(env)
    end

    # The parameters passed into the request as
    # well as parsed from URL segments.
    def params
      @params ||= Hashie::Mash.new.deep_merge(request.params).deep_merge(env['rack.routing_args'] || {})
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

      if entity_class
        embeds = {:env => env}
        embeds[:version] = env['api.version'] if env['api.version']
        body entity_class.represent(object, embeds.merge(options))
      else
        body object
      end
    end

    protected

    def run(env)
      @env = env
      @header = {}
      @request = Rack::Request.new(@env)

      self.extend helpers
      run_filters befores
      response_text = instance_eval &self.block
      run_filters afters

      [status, header, [body || response_text]]
    end

    def build_middleware
      b = Rack::Builder.new
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

      b.use Grape::Middleware::Formatter, :default_format => settings[:default_format] || :json

      aggregate_setting(:middleware).each{|m| b.use *m }

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
