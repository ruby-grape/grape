# frozen_string_literal: true

module Grape
  module ErrorFormatter
    class Xml < Base
      # Base#wrap_message always hands over a Hash, which ActiveSupport's
      # conversions (required by grape.rb) give +to_xml+.
      def self.format_structured_message(structured_message)
        structured_message.to_xml(root: :error)
      end
    end
  end
end
