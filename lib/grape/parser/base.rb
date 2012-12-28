require 'active_support/core_ext/hash/indifferent_access'

module Grape
  module Parser
    module Base

      class << self

        PARSERS = {
          :json => Grape::Parser::Json,
          :xml => Grape::Parser::Xml
        }

        def parsers(options)
          HashWithIndifferentAccess.new(
            PARSERS.merge(options[:parsers] || {})
          )
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
