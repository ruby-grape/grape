# frozen_string_literal: true

module Grape
  module Exceptions
    class UnknownParameter < Base
      def initialize(param)
        super(message: compose_message(:unknown_parameter, param:))
      end
    end
  end
end
