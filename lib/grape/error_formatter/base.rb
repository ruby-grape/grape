# frozen_string_literal: true

module Grape
  module ErrorFormatter
    class Base
      class << self
        def call(message, backtrace, options = {}, env = nil, original_exception = nil)
          wrapped_message = wrap_message(present(message, env))
          if wrapped_message.is_a?(Hash)
            wrapped_message[:backtrace] = backtrace if backtrace.present? && options.dig(:rescue_options, :backtrace)
            wrapped_message[:original_exception] = original_exception.inspect if original_exception && options.dig(:rescue_options, :original_exception)
          end

          format_structured_message(wrapped_message)
        end

        def present(message, env)
          # error! accepts a message hash with an optional :with key specifying the entity presenter.
          # Extract it here so the presenter can be resolved and the key is not serialized in the response.
          # See spec/integration/grape_entity/entity_spec.rb for examples.
          with = nil
          if message.is_a?(Hash) && message.key?(:with)
            message = message.dup
            with = message.delete(:with)
          end

          presenter = with || env[Grape::Env::API_ENDPOINT].entity_class_for_obj(message)

          unless presenter || env[Grape::Env::GRAPE_ROUTING_ARGS].nil?
            # env['api.endpoint'].route does not work when the error occurs within a middleware
            # the Endpoint does not have a valid env at this moment
            http_codes = env[Grape::Env::GRAPE_ROUTING_ARGS][:route_info].http_codes || []
            found_code = http_codes.find do |http_code|
              (http_code[0].to_i == env[Grape::Env::API_ENDPOINT].status) && http_code[2].respond_to?(:represent)
            end if env[Grape::Env::API_ENDPOINT].request

            presenter = found_code[2] if found_code
          end

          return message unless presenter

          embeds = { env: }
          embeds[:version] = env[Grape::Env::API_VERSION] if env.key?(Grape::Env::API_VERSION)
          presenter.represent(message, embeds).serializable_hash
        end

        def wrap_message(message)
          return message if message.is_a?(Hash)

          { message: }
        end

        def format_structured_message(_structured_message)
          raise NotImplementedError
        end

        private

        def inherited(klass)
          super
          ErrorFormatter.register(klass)
        end
      end
    end
  end
end
