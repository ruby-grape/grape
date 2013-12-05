module Grape
  module Parser
    module Base
      class << self
        PARSERS = {
          json: Grape::Parser::Json,
          jsonapi: Grape::Parser::Json,
          xml: Grape::Parser::Xml
        }

        def parsers(options)
          PARSERS.merge(options[:parsers] || {})
        end

        def parser_for(api_format, options = {})
          spec = parsers(options)[api_format]
          case spec
          when nil
            nil
          when Symbol
            method(spec)
          else
            spec
          end
        end
      end
    end
  end
end
