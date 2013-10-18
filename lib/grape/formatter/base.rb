module Grape
  module Formatter
    module Base

      class << self

        FORMATTERS = {
          json: Grape::Formatter::Json,
          jsonapi: Grape::Formatter::Json,
          serializable_hash: Grape::Formatter::SerializableHash,
          txt: Grape::Formatter::Txt,
          xml: Grape::Formatter::Xml
        }

        def formatters(options)
          FORMATTERS.merge(options[:formatters] || {})
        end

        def formatter_for(api_format, options = {})
          spec = formatters(options)[api_format]
          case spec
          when nil
            lambda { |obj, env| obj }
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
