# frozen_string_literal: true

module Grape
  module Validations
    # Stand-in for the +@api+ object that {ParamsScope} normally writes to.
    # Used when evaluating a single variant block of a +oneof:+ schema so that
    # the variant's validators are captured locally rather than registered on
    # the real API. Exposes only the slice of the API surface that
    # ParamsScope and its helpers touch during definition.
    class OneofCollector
      attr_reader :inheritable_setting

      def initialize
        @inheritable_setting = Grape::Util::InheritableSetting.new
        @inheritable_setting.namespace_inheritable[:do_not_document] = true
      end

      def configuration
        nil
      end

      def validators
        inheritable_setting.namespace_stackable[:validations]
      end

      def declared_params
        inheritable_setting.namespace_stackable[:declared_params]
      end

      # Evaluate +variant_block+ in a fresh +ParamsScope+ backed by a new
      # collector and return the validators that the block registered.
      def self.collect(variant_block)
        collector = new
        ParamsScope.new(api: collector, type: Hash, &variant_block)
        collector.validators
      end
    end
  end
end
