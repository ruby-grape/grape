module Grape
  module Parser
    module Json
      class << self
        def call(object, _env)
          Grape::Config.json_processor.load(object)
        rescue => e
          # handle JSON parsing errors via the rescue handlers or provide error message
          if Grape::Config.json_processor == JSON && e.is_a?(JSON::ParserError)
            raise Grape::Exceptions::InvalidMessageBody, 'application/json'
          elsif defined?(MultiJson) &&  Grape::Config.json_processor == MultiJson && e.is_a?(MultiJson::ParseError)
            raise Grape::Exceptions::InvalidMessageBody, 'application/json'
          else
            raise e
          end
        end
      end
    end
  end
end
