# frozen_string_literal: true

require 'grape/exceptions/base'

module Grape
  module Exceptions
    class Validation < Grape::Exceptions::Base
      attr_accessor :params, :message_key

      def initialize(params:, message: nil, **args)
        @params = params
        if message
          @message_key = message if message.is_a?(Symbol)
          args[:message] = translate_message(message)
        end
        super(**args)
      end

      # Remove all the unnecessary stuff from Grape::Exceptions::Base like status
      # and headers when converting a validation error to json or string
      def as_json(*_args)
        to_s
      end
    end
  end
end
