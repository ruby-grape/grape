# frozen_string_literal: true

module Grape
  if defined?(::MultiJson)
    Json = ::MultiJson
  else
    module Json
      ParseError = ::JSON::ParserError

      def self.load(str)
        ::JSON.parse(str)
      end

      def self.dump(obj, *)
        ::JSON.dump(obj, *)
      end
    end
  end
end
