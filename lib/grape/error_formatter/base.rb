module Grape
  module ErrorFormatter
    module Base

      class << self

        FORMATTERS = {
          serializable_hash: Grape::ErrorFormatter::Json,
          json: Grape::ErrorFormatter::Json,
          jsonapi: Grape::ErrorFormatter::Json,
          txt: Grape::ErrorFormatter::Txt,
          xml: Grape::ErrorFormatter::Xml
        }

        def formatters(options)
          FORMATTERS.merge(options[:error_formatters] || {})
        end

        def formatter_for(api_format, options = {})
          spec = formatters(options)[api_format]
          case spec
          when nil
            options[:default_error_formatter] || Grape::ErrorFormatter::Txt
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
