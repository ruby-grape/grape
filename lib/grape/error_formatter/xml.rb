module Grape
  module ErrorFormatter
    module Xml
      class << self

        def call(message, backtrace, options = {})
          result = message.is_a?(Hash) ? message : { :error => message }
          if (options[:rescue_options] || {})[:backtrace] && backtrace && ! backtrace.empty?
            result = result.merge({ :backtrace => backtrace })
          end
          result.respond_to?(:to_xml) ? result.to_xml : result.to_s
        end

      end
    end
  end
end
