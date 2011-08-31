require 'rack'
require 'grape'

module Grape
  # An Endpoint is the proxy scope in which all routing
  # blocks are executed. In other words, any methods
  # on the instance level of this class may be called
  # from inside a `get`, `post`, etc. block.
  class Endpoint
    def self.generate(&block)
      c = Class.new(Grape::Endpoint)
      c.class_eval do
        @block = block
      end
      c
    end
    
    class << self
      attr_accessor :block
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

    # Creates a URL to use in redirection. It takes the part
    # of the URL that would come after any version or prefix, but
    # it doesn't take current resource into consideration.
    #
    # @example Create a URL (assuming prefix of 'api' and version of 'v1')
    #   url('/content/1') #=> "http://example.org/api/v1/content/1"
    #
    # @param [String] url the relative url to create
    # @return [String] the completed url
    def url(url)
      path = request.env['api.original_path_info'] || request.env['PATH_INFO']
      corrected_path = request.env['PATH_INFO']

      # Grab the full requested url, mainly for the
      # domain information. Before PATH_INFO is changed,
      # it's not technically what was requested.
      full_url = request.url

      # See if api.original_path_info is different
      # If not, then we didn't have an api or version
      if path != corrected_path
        # Replace the non-prefix version with
        # the full version. This should make it the
        # original url again
        full_url.sub!(corrected_path, path)
      end

      # Now trim off the api part of the url so there's room
      # to attach our new section
      full_url.sub!(corrected_path, '')

      # Return the completed version
      full_url + url
    end
    
    def call(env)
      @env = env
      @header = {}
      @request = Rack::Request.new(@env)
      
      response_text = instance_eval &self.class.block
      
      [status, header, [response_text]]
    end
  end
end
