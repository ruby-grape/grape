# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class LengthValidator < Base
        def initialize(attrs, options, required, scope, opts)
          super

          @min, @max, @is = @options.values_at(:min, :max, :is)
          validate_boundary!(:min, @min)
          validate_boundary!(:max, @max)
          raise ArgumentError, "min #{@min} cannot be greater than max #{@max}" if @min && @max && @min > @max

          return if @is.nil?
          raise ArgumentError, 'is must be an integer greater than zero' unless @is.is_a?(Integer) && @is.positive?
          raise ArgumentError, 'is cannot be combined with min or max' unless @min.nil? && @max.nil?
        end

        def validate_param!(attr_name, params)
          param = params[attr_name]

          return unless param.respond_to?(:length)

          return unless (!@min.nil? && param.length < @min) || (!@max.nil? && param.length > @max) || (!@is.nil? && param.length != @is)

          validation_error!(attr_name, message do
            if @min && @max
              translate(:length, min: @min, max: @max)
            elsif @min
              translate(:length_min, min: @min)
            elsif @max
              translate(:length_max, max: @max)
            else
              translate(:length_is, is: @is)
            end
          end)
        end

        private

        def validate_boundary!(name, val)
          raise ArgumentError, "#{name} must be an integer greater than or equal to zero" if !val.nil? && (!val.is_a?(Integer) || val.negative?)
        end
      end
    end
  end
end
