# frozen_string_literal: true

module Grape
  if defined?(::MultiJson)
    Json = ::MultiJson
  else
    Json = ::JSON
    Json::ParseError = Json::ParserError
  end
end
