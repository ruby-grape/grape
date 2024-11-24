# frozen_string_literal: true

module Grape
  module Exceptions
    class Validation < Base
      attr_accessor :params, :message_key

      def initialize(params:, message: nil, status: nil, headers: nil)
        @params = params
        if message
          @message_key = message if message.is_a?(Symbol)
          message = translate_message(message)
        end

        super(status: status, message: message, headers: headers)
      end

      # Remove all the unnecessary stuff from Grape::Exceptions::Base like status
      # and headers when converting a validation error to json or string
      def as_json(*_args)
        to_s
      end
    end
  end
end
