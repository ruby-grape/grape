require 'grape/exceptions/base'

module Grape
  module Exceptions
    class Validation < Grape::Exceptions::Base
      attr_accessor :param

      def initialize(args = {})
        raise "Param is missing:" unless args.has_key? :param
        @param = args[:param]
        args[:message] = translate_message(args[:message_key]) if args.has_key? :message_key
        super
      end

      # remove all the unnecessary stuff from Grape::Exceptions::Base like status
      # and headers when converting a validation error to json or string
      def as_json(*args)
        to_s
      end

      def to_s
        message
      end
    end
  end
end
