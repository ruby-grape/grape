# frozen_string_literal: true

module Grape
  module Exceptions
    class UnknownAuthStrategy < Base
      def initialize(strategy:)
        super(message: compose_message(:unknown_auth_strategy, strategy: strategy))
      end
    end
  end
end
