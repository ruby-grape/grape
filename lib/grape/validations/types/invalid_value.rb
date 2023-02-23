# frozen_string_literal: true

module Grape
  module Validations
    module Types
      # Instances of this class may be used as tokens to denote that a parameter value could not be
      # coerced. The given message will be used as a validation error.
      class InvalidValue
        attr_reader :message

        def initialize(message = nil)
          @message = message
        end
      end
    end
  end
end
