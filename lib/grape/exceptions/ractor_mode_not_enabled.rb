# frozen_string_literal: true

module Grape
  module Exceptions
    class RactorModeNotEnabled < Base
      def initialize
        super(message: compose_message(:ractor_mode_not_enabled))
      end
    end
  end
end
