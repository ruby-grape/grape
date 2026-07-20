# frozen_string_literal: true

module Grape
  module Validations
    # Stand-in for the +@api+ object that {ParamsScope} normally writes to.
    # Used when evaluating a single variant block of a +oneof:+ schema so that
    # the variant's validators are captured locally rather than registered on
    # the real API. Exposes only the slice of the API surface that
    # ParamsScope and its helpers touch during definition.
    class OneofCollector
      extend Forwardable

      attr_reader :inheritable_setting

      def_delegator :@inheritable_setting, :validations

      def initialize
        @inheritable_setting = Grape::Util::InheritableSetting.new
        @inheritable_setting.namespace_inheritable[:do_not_document] = true
      end

      def configuration
        nil
      end

      # Evaluate +variant_block+ in a fresh +ParamsScope+ backed by a new
      # collector and return the validators that the block registered.
      def self.collect(variant_block)
        collector = new
        ParamsScope.new(api: collector, type: Hash, &variant_block)
        collector.validations
      end
    end
  end
end
