# frozen_string_literal: true

module Grape
  module Exceptions
    class Validation < Base
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
      end

      # Remove all the unnecessary stuff from Grape::Exceptions::Base like status
      # and headers when converting a validation error to json or string
      def as_json(*_args)
        to_s
      end
    end
  end
end
