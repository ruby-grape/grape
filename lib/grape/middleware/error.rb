require 'grape/middleware/base'

module Grape
  module Middleware
    class Error < Base
      def default_options
        {
          default_status: 500, # default status returned on error
          default_message: '',
          format: :txt,
          formatters: {},
          error_formatters: {},
          rescue_all: false, # true to rescue all exceptions
          rescue_subclasses: true, # rescue subclasses of exceptions listed
          rescue_options: { backtrace: false }, # true to display backtrace
          rescue_handlers: {}, # rescue handler blocks
          base_only_rescue_handlers: {}, # rescue handler blocks rescuing only the base class
          all_rescue_handler: nil # rescue handler block to rescue from all exceptions
        }
      end

      def call!(env)
        @env = env

        inject_helpers!

        begin
          error_response(catch(:error) do
            return @app.call(@env)
          end)
        rescue StandardError => e
          is_rescuable = rescuable?(e.class)
          if e.is_a?(Grape::Exceptions::Base) && !is_rescuable
            handler = ->(arg) { error_response(arg) }
          else
            raise unless is_rescuable
            handler = find_handler(e.class)
          end

          handler.nil? ? handle_error(e) : exec_handler(e, &handler)
        end
      end

      def find_handler(klass)
        handler = options[:rescue_handlers].find(-> { [] }) { |error, _| klass <= error }[1]
        handler ||= options[:base_only_rescue_handlers][klass]
        handler ||= options[:all_rescue_handler]
        with_option = options[:rescue_options][:with]
        if with_option.instance_of?(Symbol)
          if respond_to?(with_option)
            handler ||= self.class.instance_method(with_option).bind(self)
          else
            fail NoMethodError, "undefined method `#{with_option}'"
          end
        end
        handler
      end

      def rescuable?(klass)
        return false if klass == Grape::Exceptions::InvalidVersionHeader
        options[:rescue_all] || (options[:rescue_handlers] || []).any? { |error, _handler| klass <= error } || (options[:base_only_rescue_handlers] || []).include?(klass)
      end

      def exec_handler(e, &handler)
        if handler.lambda? && handler.arity == 0
          instance_exec(&handler)
        else
          instance_exec(e, &handler)
        end
      end

      def inject_helpers!
        return if helpers_available?
        endpoint = @env['api.endpoint']
        self.class.instance_eval do
          include endpoint.send(:helpers)
        end if endpoint.is_a?(Grape::Endpoint)
        @helpers = true
      end

      def helpers_available?
        @helpers
      end

      def error!(message, status = options[:default_status], headers = {}, backtrace = [])
        headers = headers.reverse_merge(Grape::Http::Headers::CONTENT_TYPE => content_type)
        rack_response(format_message(message, backtrace), status, headers)
      end

      def handle_error(e)
        error_response(message: e.message, backtrace: e.backtrace)
      end

      # TODO: This method is deprecated. Refactor out.
      def error_response(error = {})
        status = error[:status] || options[:default_status]
        message = error[:message] || options[:default_message]
        headers = { Grape::Http::Headers::CONTENT_TYPE => content_type }
        headers.merge!(error[:headers]) if error[:headers].is_a?(Hash)
        backtrace = error[:backtrace] || []
        rack_response(format_message(message, backtrace), status, headers)
      end

      def rack_response(message, status = options[:default_status], headers = { Grape::Http::Headers::CONTENT_TYPE => content_type })
        Rack::Response.new([message], status, headers).finish
      end

      def format_message(message, backtrace)
        format = env[Grape::Env::API_FORMAT] || options[:format]
        formatter = Grape::ErrorFormatter.formatter_for(format, options)
        throw :error, status: 406, message: "The requested format '#{format}' is not supported." unless formatter
        formatter.call(message, backtrace, options, env)
      end
    end
  end
end
