require 'rack'
require 'grape'
require 'hashie'

module Grape
  # An Endpoint is the proxy scope in which all routing
  # blocks are executed. In other words, any methods
  # on the instance level of this class may be called
  # from inside a `get`, `post`, etc. block.
  class Endpoint
    def self.generate(options = {}, &block)
      c = Class.new(Grape::Endpoint)
      c.class_eval do
        @block = block
        @options = options
      end
      c
    end
    
    class << self
      attr_accessor :block, :options
    end
    
    def self.call(env)
      new.call(env)
    end
    
    attr_reader :env, :request
    
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
        entity_class ||= self.class.options[:representations][potential]
      end

      if entity_class
        embeds = {:env => env}
        embeds[:version] = env['api.version'] if env['api.version']
        body entity_class.represent(object, embeds.merge(options))
      else
        body object
      end
    end

    def call(env)
      @env = env
      @header = {}
      @request = Rack::Request.new(@env)

      get_cookies

      run_filters self.class.options[:befores]
      response_text = instance_eval &self.class.block
      run_filters self.class.options[:afters]

      set_cookies

      [status, header, [body || response_text]]
    end

    protected

    def run_filters(filters)
      (filters || []).each do |filter|
        instance_eval &filter
      end
    end

    def get_cookies
      cookies.without_send do |c|
        @request.cookies.each do |name, value|
          c[name] = value
        end
      end
    end

    def set_cookies
      cookies.each(:to_send) do |name, value|
        Rack::Utils.set_cookie_header!(
            header, name, value.instance_of?(Hash) ? value : { :value => value })
      end
    end
  end
end
