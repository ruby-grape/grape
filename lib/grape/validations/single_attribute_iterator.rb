# frozen_string_literal: true

module Grape
  module Validations
    class SingleAttributeIterator < AttributesIterator
      private

      def yield_attributes(val, attrs)
        attrs.each do |attr_name|
          yield val, attr_name, empty?(val), skip?(val)
        end
      end


      # This is a special case so that we can ignore tree's where option
      # values are missing lower down. Unfortunately we can remove this
      # are the parameter parsing stage as they are required to ensure
      # the correct indexing is maintained
      def skip?(val)
        # return false
        val == Grape::DSL::Parameters::EmptyOptionalValue
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
