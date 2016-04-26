require 'grape/exceptions/base'

module Grape
  module Exceptions
    class Validation < Grape::Exceptions::Base
      attr_accessor :params
      attr_accessor :message_key

      def initialize(args = {})
        raise 'Params are missing:' unless args.key? :params
        @params = args[:params]
        if args.key?(:message)
          @message_key = args[:message] if args[:message].is_a?(Symbol)
          args[:message] = translate_message(args[:message])
        end
        super
      end

      # remove all the unnecessary stuff from Grape::Exceptions::Base like status
      # and headers when converting a validation error to json or string
      def as_json(*_args)
        to_s
      end

      def to_s
        message
      end
    end
  end
end
