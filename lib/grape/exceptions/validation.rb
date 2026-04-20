# frozen_string_literal: true

module Grape
  module Exceptions
    class Validation < Base
      EMPTY_BACKTRACE = [].freeze

      attr_reader :params, :message_key

      def initialize(params:, message: nil, status: nil, headers: nil)
        @params = Array(params)
        if message
          @message_key = case message
                         when Symbol then message
                         when Hash then message[:key]
                         end
          message = translate_message(message)
        end

        super(status:, message:, headers:)
        # Pre-seed the backtrace so Ruby's raise skips capture. Validation errors are
        # a hot path (raised per bad attribute) and end up as 400 Bad Request responses;
        # backtraces here point into Grape internals and have no diagnostic value.
        set_backtrace(EMPTY_BACKTRACE)
      end

      # Remove all the unnecessary stuff from Grape::Exceptions::Base like status
      # and headers when converting a validation error to json or string
      def as_json(*_args)
        to_s
      end
    end
  end
end
