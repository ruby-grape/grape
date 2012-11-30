module Grape
  module ErrorFormatter
    module Base

      class << self

        FORMATTERS = {
          :json => Grape::ErrorFormatter::Json,
          :txt => Grape::ErrorFormatter::Txt,
          :xml => Grape::ErrorFormatter::Xml
        }

        def formatters(options)
          FORMATTERS.merge(options[:formatters] || {})
        end

        def formatter_for(api_format, options = {})
          spec = formatters(options)[api_format]
          case spec
          when nil
            lambda { |obj| obj }
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
