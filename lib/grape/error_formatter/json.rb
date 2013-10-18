module Grape
  module ErrorFormatter
    module Json
      class << self

        def call(message, backtrace, options = {}, env = nil)
          result = message.is_a?(Hash) ? message : { error: message }
          if (options[:rescue_options] || {})[:backtrace] && backtrace && !backtrace.empty?
            result = result.merge(backtrace: backtrace)
          end
          MultiJson.dump(result)
        end

      end
    end
  end
end
