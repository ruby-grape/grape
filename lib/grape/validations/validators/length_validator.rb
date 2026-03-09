# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class LengthValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super

          @min, @max, @is = @option.values_at(:min, :max, :is)
          raise ArgumentError, 'min must be an integer greater than or equal to zero' if !@min.nil? && (!@min.is_a?(Integer) || @min.negative?)
          raise ArgumentError, 'max must be an integer greater than or equal to zero' if !@max.nil? && (!@max.is_a?(Integer) || @max.negative?)
          raise ArgumentError, "min #{@min} cannot be greater than max #{@max}" if !@min.nil? && !@max.nil? && @min > @max

          return if @is.nil?
          raise ArgumentError, 'is must be an integer greater than zero' if !@is.is_a?(Integer) || !@is.positive?
          raise ArgumentError, 'is cannot be combined with min or max' if !@min.nil? || !@max.nil?
        end

        def validate_param!(attr_name, params)
          param = params[attr_name]

          return unless param.respond_to?(:length)

          return unless (!@min.nil? && param.length < @min) || (!@max.nil? && param.length > @max) || (!@is.nil? && param.length != @is)

          validation_error!(attr_name, build_message)
        end

        private

        def build_message
          if options_key?(:message)
            @option[:message]
          elsif @min && @max
            translate(:length, min: @min, max: @max)
          elsif @min
            translate(:length_min, min: @min)
          elsif @max
            translate(:length_max, max: @max)
          else
            translate(:length_is, is: @is)
          end
        end
      end
    end
  end
end
