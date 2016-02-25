# encoding: utf-8
module Grape
  module Exceptions
    class UnsupportedGroupTypeError < Base
      def initialize
        super(message: compose_message(:unsupported_group_type))
      end
    end
  end
end
