# frozen_string_literal: true

module Grape
  module Util
    class ReverseStackableValues < StackableValues
      protected

      def concat_values(inherited_value, new_value)
        return inherited_value unless new_value

        new_value + inherited_value
      end
    end
  end
end
