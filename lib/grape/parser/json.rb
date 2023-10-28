# frozen_string_literal: true

module Grape
  module Parser
    module Json
      class << self
        def call(object, _env)
          ::Grape::Util::Json.load(object)
        rescue ::Grape::Util::Json::ParseError
          # handle JSON parsing errors via the rescue handlers or provide error message
          raise Grape::Exceptions::InvalidMessageBody.new('application/json')
        end
      end
    end
  end
end
