require 'rack'
require 'grape'

module Grape
  class Endpoint
    def initialize(&block)
      @block = block
    end
    
    attr_reader :env, :request
    
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
    
    def header(key = nil, val = nil)
      if key
        val ? @header[key.to_s] = val : @header.delete(key.to_s)
      else
        @header
      end
    end
    
    def call(env)
      @env = env
      @request = Rack::Request.new(@env)
      @header = {}
      
      response_text = instance_eval &@block
      
      [status, header, [response_text]]
    end
  end
end
