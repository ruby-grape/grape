require 'grape/middleware/base'

module Grape
  module Middleware
    class Error < Base

      def default_options
        {
          default_status: 403, # default status returned on error
          default_message: "",
          format: :txt,
          formatters: {},
          error_formatters: {},
          rescue_all: false, # true to rescue all exceptions
          rescue_options: { backtrace: false }, # true to display backtrace
          rescue_handlers: {}, # rescue handler blocks
          rescued_errors: []
        }
      end

      def call!(env)
        @env = env

        begin
          error_response(catch(:error) do
            return @app.call(@env)
          end)
        rescue StandardError => e
          is_rescuable = rescuable?(e.class)
          if e.is_a?(Grape::Exceptions::Base) && !is_rescuable
            handler = lambda { |arg| error_response(arg) }
          else
            raise unless is_rescuable
            handler = options[:rescue_handlers][e.class] || options[:rescue_handlers][:all]
          end

          handler.nil? ? handle_error(e) : exec_handler(e, &handler)
        end
      end

      def rescuable?(klass)
        options[:rescue_all] || (options[:rescued_errors] || []).include?(klass)
      end

      def exec_handler(e, &handler)
        if handler.lambda? && handler.arity == 0
          instance_exec(&handler)
        else
          instance_exec(e, &handler)
        end
      end

      def handle_error(e)
        error_response(message: e.message, backtrace: e.backtrace)
      end

      def error_response(error = {})
        status = error[:status] || options[:default_status]
        message = error[:message] || options[:default_message]
        headers = { 'Content-Type' => content_type }
        headers.merge!(error[:headers]) if error[:headers].is_a?(Hash)
        backtrace = error[:backtrace] || []
        rack_response(format_message(message, backtrace), status, headers)
      end

      def rack_response(message, status = options[:default_status], headers = { 'Content-Type' => content_type })
        Rack::Response.new([message], status, headers).finish
      end

      def format_message(message, backtrace)
        format = env['api.format'] || options[:format]
        formatter = Grape::ErrorFormatter::Base.formatter_for(format, options)
        throw :error, status: 406, message: "The requested format '#{format}' is not supported." unless formatter
        formatter.call(message, backtrace, options, env)
      end

    end
  end
end
