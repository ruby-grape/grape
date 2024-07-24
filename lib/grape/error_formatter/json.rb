# frozen_string_literal: true

module Grape
  module ErrorFormatter
    module Json
      extend Base

      class << self
        def call(message, backtrace, options = {}, env = nil, original_exception = nil)
          result = wrap_message(present(message, env))

          result = merge_rescue_options(result, backtrace, options, original_exception) if result.is_a?(Hash)

          ::Grape::Json.dump(result)
        end

        private

        def wrap_message(message)
          if message.is_a?(Hash)
            message
          elsif message.is_a?(Exceptions::ValidationErrors)
            message.as_json
          else
            { error: ensure_utf8(message) }
          end
        end

        def ensure_utf8(message)
          return message unless message.respond_to? :encode

          message.encode('UTF-8', invalid: :replace, undef: :replace)
        end

        def merge_rescue_options(result, backtrace, options, original_exception)
          rescue_options = options[:rescue_options] || {}
          result = result.merge(backtrace: backtrace) if rescue_options[:backtrace] && backtrace && !backtrace.empty?
          result = result.merge(original_exception: original_exception.inspect) if rescue_options[:original_exception] && original_exception

          result
        end
      end
    end
  end
end
