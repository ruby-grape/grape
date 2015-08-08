require 'active_support/concern'

module Grape
  module DSL
    module Environment
      extend ActiveSupport::Concern
        included do
          attr_reader :env
        end
      
        def original_path
          request = Rack::Request.new(env)
          request.path
        end
    end
  end
end