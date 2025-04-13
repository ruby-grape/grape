# frozen_string_literal: true

module Grape
  module Exceptions
    class ConflictingTypes < Base
      def initialize
        super(message: compose_message(:conflicting_types), status: 400)
      end
    end
  end
end
