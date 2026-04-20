# frozen_string_literal: true

module Grape
  module ErrorFormatter
    class Json < Base
      class << self
        def format_structured_message(structured_message)
          ::Grape::Json.dump(structured_message)
        end

        private

        def wrap_message(message)
          case message
          when Hash
            message
          when Exceptions::ValidationErrors
            message.as_json
          else
            { error: ensure_utf8(message) }
          end
        end

        def ensure_utf8(message)
          return message unless message.respond_to? :encode

          message.encode('UTF-8', invalid: :replace, undef: :replace)
        end
      end
    end
  end
end
