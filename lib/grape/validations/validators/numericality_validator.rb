# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class NumericalityValidator < Base
        COMPARISON_OPTIONS = %i[greater_than greater_than_or_equal_to less_than less_than_or_equal_to equal_to other_than].freeze

        def initialize(attrs, options, required, scope, opts)
          super

          @greater_than, @greater_than_or_equal_to, @less_than, @less_than_or_equal_to, @equal_to, @other_than =
            options.values_at(*COMPARISON_OPTIONS)
          @only_integer, @odd, @even = options.values_at(:only_integer, :odd, :even)

          validate_options!
        end

        def validate_param!(attr_name, params)
          return unless hash_like?(params)

          Array.wrap(params[attr_name]).each { |val| check_value!(attr_name, val) }
        end

        private

        def check_value!(attr_name, val)
          return unless val.is_a?(Numeric)

          check_shape!(attr_name, val)
          check_comparisons!(attr_name, val)
        end

        def check_shape!(attr_name, val)
          fail!(attr_name, :only_integer) if @only_integer && !whole?(val)
          fail!(attr_name, :odd) if @odd && val.respond_to?(:odd?) && val.even?
          fail!(attr_name, :even) if @even && val.respond_to?(:even?) && val.odd?
        end

        def check_comparisons!(attr_name, val)
          fail!(attr_name, :equal_to, @equal_to) if @equal_to && val != @equal_to
          fail!(attr_name, :other_than, @other_than) if @other_than && val == @other_than
          fail!(attr_name, :greater_than, @greater_than) if @greater_than && val <= @greater_than
          fail!(attr_name, :greater_than_or_equal_to, @greater_than_or_equal_to) if @greater_than_or_equal_to && val < @greater_than_or_equal_to
          fail!(attr_name, :less_than, @less_than) if @less_than && val >= @less_than
          fail!(attr_name, :less_than_or_equal_to, @less_than_or_equal_to) if @less_than_or_equal_to && val > @less_than_or_equal_to
        end

        def whole?(val)
          val.is_a?(Integer) || (val.respond_to?(:to_i) && val == val.to_i)
        end

        def fail!(attr_name, key, count = nil)
          validation_error!(attr_name, message { translate(:"numericality_#{key}", count:) })
        end

        def validate_options!
          validate_numeric_option!(:greater_than, @greater_than)
          validate_numeric_option!(:greater_than_or_equal_to, @greater_than_or_equal_to)
          validate_numeric_option!(:less_than, @less_than)
          validate_numeric_option!(:less_than_or_equal_to, @less_than_or_equal_to)
          validate_numeric_option!(:equal_to, @equal_to)
          validate_numeric_option!(:other_than, @other_than)

          raise ArgumentError, 'greater_than cannot be combined with greater_than_or_equal_to' if @greater_than && @greater_than_or_equal_to
          raise ArgumentError, 'less_than cannot be combined with less_than_or_equal_to' if @less_than && @less_than_or_equal_to
          raise ArgumentError, 'odd cannot be combined with even' if @odd && @even

          other_comparisons_given = @greater_than || @greater_than_or_equal_to || @less_than || @less_than_or_equal_to || @other_than
          raise ArgumentError, 'equal_to cannot be combined with other comparison options' if @equal_to && other_comparisons_given

          validate_range!
        end

        def validate_numeric_option!(name, val)
          raise ArgumentError, "#{name} must be a Numeric value" if !val.nil? && !val.is_a?(Numeric)
        end

        def validate_range!
          lower = @greater_than || @greater_than_or_equal_to
          upper = @less_than || @less_than_or_equal_to
          return unless lower && upper && lower > upper

          raise ArgumentError, "#{lower} cannot be greater than #{upper}"
        end
      end
    end
  end
end
