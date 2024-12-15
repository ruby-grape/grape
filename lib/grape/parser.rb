# frozen_string_literal: true

module Grape
  module Parser
    extend Grape::Util::Registry

    module_function

    def parser_for(format, parsers = nil)
      return parsers[format] if parsers&.key?(format)

      registry[format]
    end
  end
end
