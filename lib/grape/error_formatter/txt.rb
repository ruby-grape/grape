# frozen_string_literal: true

module Grape
  module ErrorFormatter
    module Txt
      extend Base

      class << self
        def call(message, backtrace, options = {}, env = nil, original_exception = nil)
          message = present(message, env)

          result = message.is_a?(Hash) ? ::Grape::Json.dump(message) : message
          Array.wrap(result).tap do |final_result|
            rescue_options = options[:rescue_options] || {}
            if rescue_options[:backtrace] && backtrace.present?
              final_result << 'backtrace:'
              final_result.concat(backtrace)
            end
            if rescue_options[:original_exception] && original_exception
              final_result << 'original exception:'
              final_result << original_exception.inspect
            end
          end.join("\r\n ")
        end
      end
    end
  end
end
