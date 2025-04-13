# frozen_string_literal: true

module Grape
  module Exceptions
    class TooDeepParameters < Base
      def initialize(limit)
        super(message: compose_message(:too_deep_parameters, limit: limit), status: 400)
      end
    end
  end
end
