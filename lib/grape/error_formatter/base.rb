# frozen_string_literal: true

module Grape
  module ErrorFormatter
    class Base
      class << self
        def call(message, backtrace, options = {}, env = nil, original_exception = nil)
          merge_backtrace = backtrace.present? && options.dig(:rescue_options, :backtrace)
          merge_original_exception = original_exception && options.dig(:rescue_options, :original_exception)

          wrapped_message = wrap_message(present(message, env))
          if wrapped_message.is_a?(Hash)
            wrapped_message[:backtrace] = backtrace if merge_backtrace
            wrapped_message[:original_exception] = original_exception.inspect if merge_original_exception
          end

          format_structured_message(wrapped_message)
        end

        def present(message, env)
          present_options = {}
          presented_message = message
          if presented_message.is_a?(Hash)
            presented_message = presented_message.dup
            present_options[:with] = presented_message.delete(:with)
          end

          presenter = env[Grape::Env::API_ENDPOINT].entity_class_for_obj(presented_message, present_options)

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
            embeds[:version] = env[Grape::Env::API_VERSION] if env.key?(Grape::Env::API_VERSION)
            presented_message = presenter.represent(presented_message, embeds).serializable_hash
          end

          presented_message
        end

        def wrap_message(message)
          return message if message.is_a?(Hash)

          { message: message }
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
