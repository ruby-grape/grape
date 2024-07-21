# frozen_string_literal: true

module Grape
  module Parser
    module_function

    DEFAULTS = {
      json: Grape::Parser::Json,
      jsonapi: Grape::Parser::Json,
      xml: Grape::Parser::Xml
    }.freeze

    def parser_for(format, parsers = nil)
      parsers&.key?(format) ? parsers[format] : DEFAULTS[format]
    end
  end
end
