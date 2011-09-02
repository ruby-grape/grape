require 'rack'
require 'grape'

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
      @params ||= request.params.merge(env['rack.routing_args'] || {}).inject({}) do |h,(k,v)|
        h[k.to_s] = v
        h[k.to_sym] = v
        h
      end
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

    def call(env)
      @env = env
      @header = {}
      @request = Rack::Request.new(@env)

      run_filters self.class.options[:befores]
      response_text = instance_eval &self.class.block
      run_filters self.class.options[:afters]

      [status, header, [body || response_text]]
    end

    protected

    def run_filters(filters)
      (filters || []).each do |filter|
        instance_eval &filter
      end
    end
  end
end
