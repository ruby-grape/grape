# encoding: utf-8
module Grape
  module Exceptions
    class InvalidWithOptionForRepresent < Base
      def initialize
        super(message: compose_message(:invalid_with_option_for_represent))
      end
    end
  end
end
