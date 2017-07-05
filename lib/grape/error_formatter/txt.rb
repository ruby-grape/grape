module Grape
  module ErrorFormatter
    module Txt
      extend Base

      class << self
        def call(message, backtrace, options = {}, env = nil, exception = '')
          message = present(message, env)

          result = message.is_a?(Hash) ? ::Grape::Json.dump(message) : message
          if (options[:rescue_options] || {})[:backtrace] && backtrace && !backtrace.empty?
            result += "\r\n "
            result += backtrace.join("\r\n ")
          end
          result += "\r\n #{exception}" if (options[:rescue_options] || {})[:exception] && !exception.empty?
          result
        end
      end
    end
  end
end
