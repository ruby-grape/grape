# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class LengthValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super

          @min, @max, @is = @option.values_at(:min, :max, :is)
          validate_length_options!
          @exception_message = message { build_exception_message }
        end

        def validate_param!(attr_name, params)
          param = params[attr_name]

          return unless param.respond_to?(:length)

          return unless (@min && param.length < @min) || (@max && param.length > @max) || (@is && param.length != @is)

          raise Grape::Exceptions::Validation.new(params: @scope.full_name(attr_name), message: @exception_message)
        end

        private

        def validate_length_options!
          raise ArgumentError, 'at least one of :min, :max, or :is must be specified' if [@min, @max, @is].none?

          validate_min_max!
          validate_is!
        end

        def validate_min_max!
          raise ArgumentError, 'min must be an integer greater than or equal to zero' if @min && (!@min.is_a?(Integer) || @min.negative?)
          raise ArgumentError, 'max must be an integer greater than or equal to zero' if @max && (!@max.is_a?(Integer) || @max.negative?)
          raise ArgumentError, "min #{@min} cannot be greater than max #{@max}" if @min && @max && @min > @max
        end

        def validate_is!
          return unless @is

          raise ArgumentError, 'is must be an integer greater than zero' unless @is.is_a?(Integer) && @is.positive?
          raise ArgumentError, 'is cannot be combined with min or max' if @min || @max
        end

        def build_exception_message
          if @min && @max
            { key: :length, min: @min, max: @max }.freeze
          elsif @min
            { key: :length_min, min: @min }.freeze
          elsif @max
            { key: :length_max, max: @max }.freeze
          else
            { key: :length_is, is: @is }.freeze
          end
        end
      end
    end
  end
end
