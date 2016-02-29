# encoding: utf-8
module Grape
  module Exceptions
    class MissingOption < Base
      def initialize(option)
        super(message: compose_message(:missing_option, option: option))
      end
    end
  end
end
