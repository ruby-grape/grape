# frozen_string_literal: true

module Grape
  module Validations
    class SingleAttributeIterator < AttributesIterator
      private

      def yield_attributes(val)
        return if skip?(val)

        # The emptiness of the scope's params is the same answer for every
        # attribute in it, and answering it costs a +respond_to?+, so it is
        # asked once for the whole list rather than once per attribute.
        empty_val = empty?(val)
        @attrs.each { |attr_name| yield val, attr_name, empty_val }
      end

      # Primitives like Integers and Booleans don't respond to +empty?+.
      # It could be possible to use +blank?+ instead, but
      #
      #     false.blank?
      #     => true
      def empty?(val)
        val.respond_to?(:empty?) ? val.empty? : val.nil?
      end
    end
  end
end
