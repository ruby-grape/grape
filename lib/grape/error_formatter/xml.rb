module Grape
  module ErrorFormatter
    module Xml
      extend Base

      class << self
        def call(message, backtrace, options = {}, env = nil, original_exception = nil)
          message = present(message, env)

          result = message.is_a?(Hash) ? message : { message: message }
          if (options[:rescue_options] || {})[:backtrace] && backtrace && !backtrace.empty?
            result = result.merge(backtrace: backtrace)
          end
          if (options[:rescue_options] || {})[:original_exception] && original_exception
            result = result.merge(original_exception: original_exception.inspect)
          end
          result.respond_to?(:to_xml) ? result.to_xml(root: :error) : result.to_s
        end
      end
    end
  end
end
