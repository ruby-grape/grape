module Grape
  module Parser
    module Json
      class << self
        def call(object, _env)
          JSON.load(object)
        rescue ::JSON::ParserError
          # handle JSON parsing errors via the rescue handlers or provide error message
          raise Grape::Exceptions::InvalidMessageBody, 'application/json'
        end
      end
    end
  end
end
