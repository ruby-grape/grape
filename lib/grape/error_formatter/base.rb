module Grape
  module ErrorFormatter
    module Base
      def present(message, env)
        present_options = {}
        present_options[:with] = message.delete(:with) if message.is_a?(Hash)

        presenter = env[Grape::Env::API_ENDPOINT].entity_class_for_obj(message, present_options)

        unless presenter || env[Grape::Env::GRAPE_ROUTING_ARGS].nil?
          # env['api.endpoint'].route does not work when the error occurs within a middleware
          # the Endpoint does not have a valid env at this moment
          http_codes = env[Grape::Env::GRAPE_ROUTING_ARGS][:route_info].http_codes || []
          found_code = http_codes.find do |http_code|
            (http_code[0].to_i == env[Grape::Env::API_ENDPOINT].status) && http_code[2].respond_to?(:represent)
          end if env[Grape::Env::API_ENDPOINT].request

          presenter = found_code[2] if found_code
        end

        if presenter
          embeds = { env: env }
          embeds[:version] = env[Grape::Env::API_VERSION] if env[Grape::Env::API_VERSION]
          message = presenter.represent(message, embeds).serializable_hash
        end

        message
      end
    end
  end
end
