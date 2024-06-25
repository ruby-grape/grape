# frozen_string_literal: true

module Grape
  module Middleware
    class Error < Base
      def default_options
        {
          default_status: 500, # default status returned on error
          default_message: '',
          format: :txt,
          helpers: nil,
          formatters: {},
          error_formatters: {},
          rescue_all: false, # true to rescue all exceptions
          rescue_grape_exceptions: false,
          rescue_subclasses: true, # rescue subclasses of exceptions listed
          rescue_options: {
            backtrace: false, # true to display backtrace, true to let Grape handle Grape::Exceptions
            original_exception: false # true to display exception
          },
          rescue_handlers: {}, # rescue handler blocks
          base_only_rescue_handlers: {}, # rescue handler blocks rescuing only the base class
          all_rescue_handler: nil # rescue handler block to rescue from all exceptions
        }
      end

      def initialize(app, *options)
        super
        self.class.send(:include, @options[:helpers]) if @options[:helpers]
      end

      def call!(env)
        @env = env
        error_response(catch(:error) { return @app.call(@env) })
      rescue Exception => e # rubocop:disable Lint/RescueException
        run_rescue_handler(find_handler(e.class), e, @env[Grape::Env::API_ENDPOINT])
      end

      private

      def rack_response(status, headers, message)
        message = Rack::Utils.escape_html(message) if headers[Rack::CONTENT_TYPE] == TEXT_HTML
        Rack::Response.new(Array.wrap(message), Rack::Utils.status_code(status), Grape::Util::Header.new.merge(headers))
      end

      def format_message(message, backtrace, original_exception = nil)
        format = env[Grape::Env::API_FORMAT] || options[:format]
        formatter = Grape::ErrorFormatter.formatter_for(format, **options)
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
        message = error[:message] || options[:default_message]
        headers = { Rack::CONTENT_TYPE => content_type }.tap do |h|
          h.merge!(error[:headers]) if error[:headers].is_a?(Hash)
        end
        backtrace = error[:backtrace] || error[:original_exception]&.backtrace || []
        original_exception = error.is_a?(Exception) ? error : error[:original_exception] || nil
        rack_response(status, headers, format_message(message, backtrace, original_exception))
      end

      def default_rescue_handler(exception)
        error_response(message: exception.message, backtrace: exception.backtrace, original_exception: exception)
      end

      def rescue_handler_for_base_only_class(klass)
        error, handler = options[:base_only_rescue_handlers].find { |err, _handler| klass == err }

        return unless error

        handler || method(:default_rescue_handler)
      end

      def rescue_handler_for_class_or_its_ancestor(klass)
        error, handler = options[:rescue_handlers].find { |err, _handler| klass <= err }

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
        if handler.instance_of?(Symbol)
          raise NoMethodError, "undefined method '#{handler}'" unless respond_to?(handler)

          handler = public_method(handler)
        end

        response = catch(:error) do
          handler.arity.zero? ? endpoint.instance_exec(&handler) : endpoint.instance_exec(error, &handler)
        end

        response = error!(response[:message], response[:status], response[:headers]) if error?(response)

        if response.is_a?(Rack::Response)
          response
        else
          run_rescue_handler(:default_rescue_handler, Grape::Exceptions::InvalidResponse.new, endpoint)
        end
      end

      def error!(message, status = options[:default_status], headers = {}, backtrace = [], original_exception = nil)
        rack_response(
          status, headers.reverse_merge(Rack::CONTENT_TYPE => content_type),
          format_message(message, backtrace, original_exception)
        )
      end

      def error?(response)
        response.is_a?(Hash) && response[:message] && response[:status] && response[:headers]
      end
    end
  end
end
