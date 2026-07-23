# frozen_string_literal: true

module Grape
  module Validations
    # Frozen value object holding everything {ParamsScope#validates} needs to
    # know about a single +requires+/+optional+ declaration. Built once from
    # the raw validations hash supplied by the DSL; the raw hash is never
    # mutated.
    #
    # Splits the raw entries into three logical buckets:
    #
    # * Spec-consumed keys (type/types/coerce*, presence/message,
    #   default/fail_fast, doc keys) — exposed via named accessors and never
    #   handed to validator dispatch.
    # * Shared opts (allow_blank, fail_fast) — read by every validator at
    #   construction time via {#shared_opts}.
    # * Validator entries (everything else, e.g. +regexp+, +length+, +values+,
    #   +allow_blank+, custom validators) — exposed via {#validator_entries}
    #   for the dispatch loop.
    #
    # Same key can land in more than one bucket (e.g. +allow_blank+ is both a
    # shared opt and a validator entry; +length+ is both a doc source and a
    # validator entry).
    class ValidationsSpec
      # Keys consumed by the spec itself; must NOT be dispatched as validators
      # by the caller. Documentation-only keys are filtered through a separate
      # set so that dual-purpose keys (length, default, values, except_values)
      # aren't accidentally swallowed.
      SPEC_CONSUMED_KEYS = %i[
        type types coerce coerce_with coerce_message
        presence message
        fail_fast
        desc description documentation
      ].freeze

      attr_reader :raw, :coerce_type, :coerce_method, :coerce_message, :presence_options, :values, :except_values, :default, :allow_blank, :fail_fast, :shared_opts, :validator_entries

      def self.from(validations)
        new(validations)
      end

      def initialize(raw)
        raise ArgumentError, ':type may not be supplied with :types' if raw.key?(:type) && raw.key?(:types)

        @raw = raw
        @coerce_type, @coerce_message, @coerce_method = parse_coerce(raw)
        @values = resolve_value(raw[:values])
        @except_values = resolve_value(raw[:except_values])
        @default = raw[:default]
        @presence_options = raw[:presence]
        @allow_blank = resolve_value(raw[:allow_blank])
        @fail_fast = raw[:fail_fast] || false

        @shared_opts = { allow_blank: @allow_blank, fail_fast: @fail_fast }.freeze
        @validator_entries = build_validator_entries(raw)

        validate!

        freeze
      end

      def required?
        !@presence_options.nil? && @presence_options != false
      end

      def coerce_options
        CoerceOptions.new(type: @coerce_type, coerce_method: @coerce_method, message: @coerce_message)
      end

      private

      # Cross-field consistency checks on the parsed declaration. Run at
      # construction so an incoherent spec (e.g. a +default+ outside +values+,
      # or +values+ whose elements don't match +type+) can never exist —
      # callers no longer have to remember to invoke these separately.
      def validate!
        guessed_coerce_type = guess_coerce_type(@coerce_type, @values, @except_values)
        check_incompatible_option_values(@default, @values, @except_values)
        validate_value_coercion(guessed_coerce_type, @values, @except_values)
      end

      def check_incompatible_option_values(default, values, except_values)
        return if default.nil? || default.is_a?(Proc)

        raise Grape::Exceptions::IncompatibleOptionValues.new(:default, default, :values, values) if values && !values.is_a?(Proc) && Array(default).any? { |def_val| !values.include?(def_val) }

        return unless except_values && !except_values.is_a?(Proc) && Array(default).any? { |def_val| except_values.include?(def_val) }

        raise Grape::Exceptions::IncompatibleOptionValues.new(:default, default, :except, except_values)
      end

      def validate_value_coercion(coerce_type, *values_list)
        return unless coerce_type

        coerce_type = coerce_type.first if coerce_type.is_a?(Enumerable)
        values_list.each do |values|
          next if !values || values.is_a?(Proc)

          value_types = values.is_a?(Range) ? [values.begin, values.end].compact : values
          value_types = value_types.map { |type| Grape::API::Boolean.build(type) } if coerce_type == Grape::API::Boolean
          raise Grape::Exceptions::IncompatibleOptionValues.new(:type, coerce_type, :values, values) unless value_types.all?(coerce_type)
        end
      end

      def build_validator_entries(raw)
        raw.reject do |k, _|
          SPEC_CONSUMED_KEYS.include?(k) || ParamsScope::RESERVED_DOCUMENTATION_KEYWORDS.include?(k)
        end.freeze
      end

      def parse_coerce(raw)
        if raw.key?(:type)
          coerce, coerce_message = extract_value_and_message(raw[:type])
          coerce_with = raw[:coerce_with]
          return [Types::VariantCollectionCoercer.new(coerce, coerce_with), coerce_message, nil] if Types.multiple?(coerce)
        elsif raw.key?(:types)
          coerce, coerce_message = extract_value_and_message(raw[:types])
          coerce_with = raw[:coerce_with]
        else
          coerce = raw[:coerce]
          coerce_message = raw[:coerce_message]
          coerce_with = raw[:coerce_with]
        end

        [coerce, coerce_message, coerce_with]
      end

      def extract_value_and_message(opt)
        return [opt, nil] unless opt.is_a?(Hash)

        [opt[:value], opt[:message]]
      end

      def resolve_value(opt)
        opt.is_a?(Hash) ? opt[:value] : opt
      end

      def guess_coerce_type(coerce_type, *values_list)
        return coerce_type unless coerce_type == Array

        values_list.each do |values|
          next if !values || values.is_a?(Proc)
          return values.first.class if values.is_a?(Range) || !values.empty?
        end
        coerce_type
      end
    end
  end
end
