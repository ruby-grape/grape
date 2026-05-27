# frozen_string_literal: true

module Grape
  module Middleware
    class Error < Base
      extend Forwardable
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
        internal_grape_exceptions_rescue_handler: nil,
        rescue_all: false,
        rescue_grape_exceptions: false,
        rescue_handlers: nil,
        rescue_options: Grape::DSL::RescueOptions.new
      }.freeze

      attr_reader :all_rescue_handler, :base_only_rescue_handlers, :default_error_formatter,
                  :default_message, :default_status, :error_formatters, :format,
                  :grape_exceptions_rescue_handler, :internal_grape_exceptions_rescue_handler,
                  :rescue_all, :rescue_grape_exceptions, :rescue_handlers, :rescue_options

      # +:backtrace+ / +:original_exception+ on the rescue options become
      # +#include_backtrace+ / +#include_original_exception+ on the middleware,
      # which is what the formatter call site reads.
      def_delegator :rescue_options, :backtrace, :include_backtrace
      def_delegator :rescue_options, :original_exception, :include_original_exception

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
        @internal_grape_exceptions_rescue_handler = @options[:internal_grape_exceptions_rescue_handler]
        @rescue_all = @options[:rescue_all]
        @rescue_grape_exceptions = @options[:rescue_grape_exceptions]
        @rescue_handlers = @options[:rescue_handlers]
        @rescue_options = @options[:rescue_options] || Grape::DSL::RescueOptions.new
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

      def format_message(error)
        current_format = env[Grape::Env::API_FORMAT] || format
        formatter = Grape::ErrorFormatter.formatter_for(current_format, error_formatters, default_error_formatter)
        return formatter.call(error:, env:, include_backtrace:, include_original_exception:) if formatter

        throw :error, Grape::Exceptions::ErrorResponse.new(
          status: 406,
          message: "The requested format '#{current_format}' is not supported.",
          backtrace: error.backtrace,
          original_exception: error.original_exception
        )
      end

      def find_handler(klass)
        registered_rescue_handler(klass) ||
          rescue_handler_for_grape_exception(klass) ||
          rescue_handler_for_any_class(klass) ||
          raise
      end

      def error_response(error = nil)
        raw = Grape::Exceptions::ErrorResponse.coerce(error)
        headers = { Rack::CONTENT_TYPE => content_type }
        headers.merge!(raw.headers) if raw.headers.is_a?(Hash)
        payload = raw.with(
          status: raw.status || default_status,
          message: raw.message || default_message,
          headers:,
          backtrace: raw.backtrace || raw.original_exception&.backtrace || []
        )
        env[Grape::Env::API_ENDPOINT].status(payload.status) # error! may not have been called
        rack_response(payload.status, payload.headers, format_message(payload))
      end

      def default_rescue_handler(exception)
        error_response(
          Grape::Exceptions::ErrorResponse.new(
            message: exception.message,
            backtrace: exception.backtrace,
            original_exception: exception
          )
        )
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

      def run_rescue_handler(handler, error, endpoint, redispatched: false)
        handler = endpoint.public_method(handler) if handler.is_a?(Symbol)
        response = catch(:error) do
          handler.arity.zero? ? endpoint.instance_exec(&handler) : endpoint.instance_exec(error, &handler)
        rescue StandardError => e
          return redispatch(e, endpoint, redispatched)
        end

        return error_response(response) if error?(response)
        return response if response.is_a?(Rack::Response)

        run_rescue_handler(method(:default_rescue_handler), Grape::Exceptions::InvalidResponse.new, endpoint)
      end

      # Route an exception raised inside a +rescue_from+ block.
      #
      # * If we have already redispatched once (the redispatched handler
      #   itself raised), go straight to {#framework_default} — bounds the
      #   chain at one redispatch.
      # * Else if the exception has a registered +rescue_from+ handler,
      #   run it.
      # * Else if it's a +Grape::Exceptions::Base+ subclass, render it
      #   through +error_response+ with its own +status+ and +message+.
      # * Else fall through to {#safe_default}, which lets the user opt
      #   in via +rescue_from :internal_grape_exceptions+ or, failing
      #   that, applies the framework default.
      def redispatch(error, endpoint, already_redispatched)
        return framework_default(endpoint) if already_redispatched

        registered = registered_rescue_handler(error.class)

        return run_rescue_handler(registered, error, endpoint, redispatched: true) if registered
        return run_rescue_handler(method(:error_response), error, endpoint, redispatched: true) if error.is_a?(Grape::Exceptions::Base)

        safe_default(error, endpoint)
      end

      # The unrecognised-error path. Exposes the original exception on
      # the rack env so upstream Rack middleware (loggers, error
      # trackers) can observe it. If the user registered a
      # +rescue_from :internal_grape_exceptions+ handler, that handler
      # runs and owns the response. Otherwise the framework renders the
      # generic +InternalServerError+ — never the original exception's
      # message. The framework deliberately does no logging of its own
      # here; that's the application's call.
      def safe_default(error, endpoint)
        env[Grape::Env::GRAPE_EXCEPTION] = error
        return run_rescue_handler(internal_grape_exceptions_rescue_handler, error, endpoint, redispatched: true) if internal_grape_exceptions_rescue_handler

        framework_default(endpoint)
      end

      def framework_default(endpoint)
        run_rescue_handler(method(:default_rescue_handler), Grape::Exceptions::InternalServerError.new, endpoint)
      end

      def error!(message, status = default_status, headers = {}, backtrace = [], original_exception = nil)
        env[Grape::Env::API_ENDPOINT].status(status) # not error! inside route
        merged_headers = { Rack::CONTENT_TYPE => content_type }.merge!(headers)
        error = Grape::Exceptions::ErrorResponse.new(
          status:, message:, headers: merged_headers, backtrace:, original_exception:
        )
        rack_response(status, merged_headers, format_message(error))
      end

      def error?(response)
        case response
        when Grape::Exceptions::ErrorResponse
          true
        when Hash
          return false unless response.key?(:message) && response.key?(:status) && response.key?(:headers)

          Grape.deprecator.warn(
            'Returning or throwing a Hash from a rescue handler is deprecated. ' \
            'Use `error!(...)` or a `Grape::Exceptions::ErrorResponse` instead.'
          )
          true
        else
          false
        end
      end
    end
  end
end
