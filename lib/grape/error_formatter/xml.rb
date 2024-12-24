# frozen_string_literal: true

module Grape
  module ErrorFormatter
    class Xml < Base
      def self.format_structured_message(structured_message)
        structured_message.respond_to?(:to_xml) ? structured_message.to_xml(root: :error) : structured_message.to_s
      end
    end
  end
end
