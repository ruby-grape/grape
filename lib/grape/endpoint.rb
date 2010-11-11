require 'rack'
require 'grape'

module Grape
  class Endpoint
    def initialize(&block)
      @block = block
    end
    
    attr_reader :env, :request
        
    def call(env)
      @env = env
      @request = Rack::Request.new(@env)
      @headers = {}
      
      response_text = instance_eval &@block
      [200, {}, [response_text]]
    end
  end
end
