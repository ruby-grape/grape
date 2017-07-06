module Grape
  module ErrorFormatter
    module Txt
      extend Base

      class << self
        def call(message, backtrace, options = {}, env = nil, original_exception = nil)
          message = present(message, env)

          result = message.is_a?(Hash) ? ::Grape::Json.dump(message) : message
          if (options[:rescue_options] || {})[:backtrace] && backtrace && !backtrace.empty?
            result += "\r\n "
            result += backtrace.join("\r\n ")
          end
          if (options[:rescue_options] || {})[:original_exception] && original_exception
            result += "\r\n #{original_exception.inspect}"
          end
          result
        end
      end
    end
  end
end
