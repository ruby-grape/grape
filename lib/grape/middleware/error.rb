# frozen_string_literal: true

module Grape
  module Middleware
    class Error < Base
      include PrecomputedContentTypes

      DEFAULT_OPTIONS = {
        all_rescue_handler: nil,
        base_only_rescue_handlers: nil,
        default_error_formatter: nil,
        default_message: '',
        default_status: 500,
        error_formatters: nil,
        format: :txt,
        grape_exceptions_rescue_handler: nil,
        rescue_all: false,
        rescue_grape_exceptions: false,
        rescue_handlers: nil,
        rescue_options: {
          backtrace: false,
          original_exception: false
        }.freeze
      }.freeze

      attr_reader :all_rescue_handler, :base_only_rescue_handlers, :default_error_formatter,
                  :default_message, :default_status, :error_formatters, :format,
                  :grape_exceptions_rescue_handler, :rescue_all, :rescue_grape_exceptions,
                  :rescue_handlers

      def initialize(app, **options)
        super
        @all_rescue_handler = @options[:all_rescue_handler]
        @base_only_rescue_handlers = @options[:base_only_rescue_handlers]
        @default_error_formatter = @options[:default_error_formatter]
        @default_message = @options[:default_message]
        @default_status = @options[:default_status]
        @error_formatters = @options[:error_formatters]
        @format = @options[:format]
        @grape_exceptions_rescue_handler = @options[:grape_exceptions_rescue_handler]
        @rescue_all = @options[:rescue_all]
        @rescue_grape_exceptions = @options[:rescue_grape_exceptions]
        @rescue_handlers = @options[:rescue_handlers]
      end

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
        current_format = env[Grape::Env::API_FORMAT] || format
        formatter = Grape::ErrorFormatter.formatter_for(current_format, error_formatters, default_error_formatter)
        return formatter.call(message, backtrace, options, env, original_exception) if formatter

        throw :error,
              status: 406,
              message: "The requested format '#{current_format}' is not supported.",
              backtrace:,
              original_exception:
      end

      def find_handler(klass)
        registered_rescue_handler(klass) ||
          rescue_handler_for_grape_exception(klass) ||
          rescue_handler_for_any_class(klass) ||
          raise
      end

      def error_response(error = {})
        status = error[:status] || default_status
        env[Grape::Env::API_ENDPOINT].status(status) # error! may not have been called
        message = error[:message] || default_message
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

      def registered_rescue_handler(klass)
        rescue_handler_from(base_only_rescue_handlers) { |err| klass == err } ||
          rescue_handler_from(rescue_handlers) { |err| klass <= err }
      end

      def rescue_handler_from(handlers)
        error, handler = handlers&.find { |err, _handler| yield(err) }

        return unless error

        handler || method(:default_rescue_handler)
      end

      def rescue_handler_for_grape_exception(klass)
        return unless klass <= Grape::Exceptions::Base
        return method(:error_response) if klass == Grape::Exceptions::InvalidVersionHeader
        return unless rescue_grape_exceptions || !rescue_all

        grape_exceptions_rescue_handler || method(:error_response)
      end

      def rescue_handler_for_any_class(klass)
        return unless klass <= StandardError
        return unless rescue_all || rescue_grape_exceptions

        all_rescue_handler || method(:default_rescue_handler)
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

      def error!(message, status = default_status, headers = {}, backtrace = [], original_exception = nil)
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
