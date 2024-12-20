# frozen_string_literal: true

module Grape
  module ErrorFormatter
    class Txt < Base
      def self.format_structured_message(structured_message)
        message = structured_message[:message] || Grape::Json.dump(structured_message)
        Array.wrap(message).tap do |final_message|
          if structured_message.key?(:backtrace)
            final_message << 'backtrace:'
            final_message.concat(structured_message[:backtrace])
          end
          if structured_message.key?(:original_exception)
            final_message << 'original exception:'
            final_message << structured_message[:original_exception]
          end
        end.join("\r\n ")
      end
    end
  end
end
