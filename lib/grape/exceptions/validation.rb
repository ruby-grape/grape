require 'grape/exceptions/base'

module Grape
  module Exceptions
    class Validation < Grape::Exceptions::Base
      attr_accessor :param

      def initialize(args = {})
        @param = args[:param].to_s if args.has_key? :param
        attribute = translate_attribute(@param)
        args[:message] = translate_message(args[:message_key], :attribute => attribute)
        super
      end
    end
  end
end
