# frozen_string_literal: true

module Grape
  module Middleware
    class Error < Base
      DEFAULT_OPTIONS = {
        default_status: 500,
        default_message: '',
        format: :txt,
        rescue_all: false,
        rescue_grape_exceptions: false,
        rescue_subclasses: true,
        rescue_options: {
          backtrace: false,
          original_exception: false
        }.freeze
      }.freeze

      def call!(env)
        @env = env
        error_response(catch(:error) { return @app.call(@env) })
      rescue Exception => e # rubocop:disable Lint/RescueException
        run_rescue_handler(find_handler(e.class), e, @env[Grape::Env::API_ENDPOINT])
      end

      private

      def rack_response(status, headers, message)
        message = Rack::Utils.escape_html(message) if headers[Rack::CONTENT_TYPE] == 'text/html'
        Rack::Response.new(Array.wrap(message), Rack::Utils.status_code(status), Grape::Util::Header.new.merge(headers))
      end

      def format_message(message, backtrace, original_exception = nil)
        format = env[Grape::Env::API_FORMAT] || options[:format]
        formatter = Grape::ErrorFormatter.formatter_for(format, options[:error_formatters], options[:default_error_formatter])
        return formatter.call(message, backtrace, options, env, original_exception) if formatter

        throw :error,
              status: 406,
              message: "The requested format '#{format}' is not supported.",
              backtrace: backtrace,
              original_exception: original_exception
      end

      def find_handler(klass)
        rescue_handler_for_base_only_class(klass) ||
          rescue_handler_for_class_or_its_ancestor(klass) ||
          rescue_handler_for_grape_exception(klass) ||
          rescue_handler_for_any_class(klass) ||
          raise
      end

      def error_response(error = {})
        status = error[:status] || options[:default_status]
        env[Grape::Env::API_ENDPOINT].status(status) # error! may not have been called
        message = error[:message] || options[:default_message]
        headers = { Rack::CONTENT_TYPE => content_type }.tap do |h|
          h.merge!(error[:headers]) if error[:headers].is_a?(Hash)
        end
        backtrace = error[:backtrace] || error[:original_exception]&.backtrace || []
        original_exception = error.is_a?(Exception) ? error : error[:original_exception]
        rack_response(status, headers, format_message(message, backtrace, original_exception))
      end

      def default_rescue_handler(exception)
        error_response(message: exception.message, backtrace: exception.backtrace, original_exception: exception)
      end

      def rescue_handler_for_base_only_class(klass)
        error, handler = options[:base_only_rescue_handlers]&.find { |err, _handler| klass == err }

        return unless error

        handler || method(:default_rescue_handler)
      end

      def rescue_handler_for_class_or_its_ancestor(klass)
        error, handler = options[:rescue_handlers]&.find { |err, _handler| klass <= err }

        return unless error

        handler || method(:default_rescue_handler)
      end

      def rescue_handler_for_grape_exception(klass)
        return unless klass <= Grape::Exceptions::Base
        return method(:error_response) if klass == Grape::Exceptions::InvalidVersionHeader
        return unless options[:rescue_grape_exceptions] || !options[:rescue_all]

        options[:grape_exceptions_rescue_handler] || method(:error_response)
      end

      def rescue_handler_for_any_class(klass)
        return unless klass <= StandardError
        return unless options[:rescue_all] || options[:rescue_grape_exceptions]

        options[:all_rescue_handler] || method(:default_rescue_handler)
      end

      def run_rescue_handler(handler, error, endpoint)
        handler = endpoint.public_method(handler) if handler.instance_of?(Symbol)
        response = catch(:error) do
          handler.arity.zero? ? endpoint.instance_exec(&handler) : endpoint.instance_exec(error, &handler)
        end

        if error?(response)
          error_response(response)
        elsif response.is_a?(Rack::Response)
          response
        else
          run_rescue_handler(method(:default_rescue_handler), Grape::Exceptions::InvalidResponse.new, endpoint)
        end
      end

      def error!(message, status = options[:default_status], headers = {}, backtrace = [], original_exception = nil)
        env[Grape::Env::API_ENDPOINT].status(status) # not error! inside route
        rack_response(
          status, headers.reverse_merge(Rack::CONTENT_TYPE => content_type),
          format_message(message, backtrace, original_exception)
        )
      end

      def error?(response)
        return false unless response.is_a?(Hash)

        response.key?(:message) && response.key?(:status) && response.key?(:headers)
      end
    end
  end
end
