# frozen_string_literal: true

module Grape
  module Util
    if defined?(::MultiJson)
      Json = ::MultiJson
    else
      Json = ::JSON
      Json::ParseError = Json::ParserError
    end
  end
end
