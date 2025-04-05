# frozen_string_literal: true

module Grape
  module Exceptions
    class InvalidParameters < Base
      def initialize
        super(message: compose_message(:invalid_parameters), status: 400)
      end
    end
  end
end
