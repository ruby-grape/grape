module Grape
  module Formatter
    class << self
      def builtin_formmaters
        {
          json: Grape::Formatter::Json,
          jsonapi: Grape::Formatter::Json,
          serializable_hash: Grape::Formatter::SerializableHash,
          txt: Grape::Formatter::Txt,
          xml: Grape::Formatter::Xml
        }
      end

      def formatters(options)
        builtin_formmaters.merge(options[:formatters] || {})
      end

      def formatter_for(api_format, options = {})
        spec = formatters(options)[api_format]
        case spec
        when nil
          ->(obj, _env) { obj }
        when Symbol
          method(spec)
        else
          spec
        end
      end
    end
  end
end
