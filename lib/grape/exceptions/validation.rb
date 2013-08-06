require 'grape/exceptions/base'

module Grape
  module Exceptions
    class Validation < Grape::Exceptions::Base
      attr_accessor :param

      def initialize(args = {})
        raise "Param is missing:" unless args.has_key? :param
        @param = args[:param].to_s
        attribute = translate_attribute(@param)
        args[:message] = translate_message(args[:message_key]) if args.has_key? :message_key
        super
      end
    end
  end
end
