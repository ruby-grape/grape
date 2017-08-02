require 'grape/middleware/base'

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
            original_exception: false, # true to display exception
          },
          rescue_handlers: {}, # rescue handler blocks
          base_only_rescue_handlers: {}, # rescue handler blocks rescuing only the base class
          all_rescue_handler: nil # rescue handler block to rescue from all exceptions
        }
      end

      def initialize(app, **options)
        super
        self.class.send(:include, @options[:helpers]) if @options[:helpers]
      end

      def call!(env)
        @env = env

        begin
          error_response(catch(:error) do
            return @app.call(@env)
          end)
        rescue StandardError => e
          is_rescuable = rescuable?(e.class)
          if e.is_a?(Grape::Exceptions::Base) && (!is_rescuable || rescuable_by_grape?(e.class))
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

        if handler.instance_of?(Symbol)
          raise NoMethodError, "undefined method `#{handler}'" unless respond_to?(handler)
          handler = self.class.instance_method(handler).bind(self)
        end

        handler
      end

      def rescuable?(klass)
        return false if klass == Grape::Exceptions::InvalidVersionHeader
        rescue_all? || rescue_class_or_its_ancestor?(klass) || rescue_with_base_only_handler?(klass)
      end

      def rescuable_by_grape?(klass)
        return false if klass == Grape::Exceptions::InvalidVersionHeader
        options[:rescue_grape_exceptions]
      end

      def exec_handler(e, &handler)
        if handler.lambda? && handler.arity.zero?
          instance_exec(&handler)
        else
          instance_exec(e, &handler)
        end
      end

      def error!(message, status = options[:default_status], headers = {}, backtrace = [], original_exception = nil)
        headers = headers.reverse_merge(Grape::Http::Headers::CONTENT_TYPE => content_type)
        rack_response(format_message(message, backtrace, original_exception), status, headers)
      end

      def handle_error(e)
        error_response(message: e.message, backtrace: e.backtrace, original_exception: e)
      end

      # TODO: This method is deprecated. Refactor out.
      def error_response(error = {})
        status = error[:status] || options[:default_status]
        message = error[:message] || options[:default_message]
        headers = { Grape::Http::Headers::CONTENT_TYPE => content_type }
        headers.merge!(error[:headers]) if error[:headers].is_a?(Hash)
        backtrace = error[:backtrace] || error[:original_exception] && error[:original_exception].backtrace || []
        original_exception = error.is_a?(Exception) ? error : error[:original_exception] || nil
        rack_response(format_message(message, backtrace, original_exception), status, headers)
      end

      def rack_response(message, status = options[:default_status], headers = { Grape::Http::Headers::CONTENT_TYPE => content_type })
        Rack::Response.new([message], status, headers).finish
      end

      def format_message(message, backtrace, original_exception = nil)
        format = env[Grape::Env::API_FORMAT] || options[:format]
        formatter = Grape::ErrorFormatter.formatter_for(format, options)
        throw :error,
              status: 406,
              message: "The requested format '#{format}' is not supported.",
              backtrace: backtrace,
              original_exception: original_exception unless formatter
        formatter.call(message, backtrace, options, env, original_exception)
      end

      private

      def rescue_all?
        options[:rescue_all]
      end

      def rescue_class_or_its_ancestor?(klass)
        (options[:rescue_handlers] || []).any? { |error, _handler| klass <= error }
      end

      def rescue_with_base_only_handler?(klass)
        (options[:base_only_rescue_handlers] || []).include?(klass)
      end
    end
  end
end
