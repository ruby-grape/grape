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

      module_function

      def present(message, env)
        present_options = {}
        present_options[:with] = message.delete(:with) if message.is_a?(Hash)

        presenter = env['api.endpoint'].entity_class_for_obj(message, present_options)

        unless presenter || env['rack.routing_args'].nil?
          # env['api.endpoint'].route does not work when the error occurs within a middleware
          # the Endpoint does not have a valid env at this moment
          http_codes = env['rack.routing_args'][:route_info].route_http_codes || []
          found_code = http_codes.find do |http_code|
            (http_code[0].to_i == env['api.endpoint'].status) && http_code[2].respond_to?(:represent)
          end

          presenter = found_code[2] if found_code
        end

        if presenter
          embeds = { env: env }
          embeds[:version] = env['api.version'] if env['api.version']
          message = presenter.represent(message, embeds).serializable_hash
        end

        message
      end
    end
  end
end
