# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class LengthValidator < Base
        def initialize(attrs, options, required, scope, opts)
          @min = options[:min]
          @max = options[:max]
          @is = options[:is]

          super

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

          raise Grape::Exceptions::Validation.new(params: [@scope.full_name(attr_name)], message: build_message)
        end

        def build_message
          if options_key?(:message)
            @option[:message]
          elsif @min && @max
            format I18n.t(:length, scope: 'grape.errors.messages'), min: @min, max: @max
          elsif @min
            format I18n.t(:length_min, scope: 'grape.errors.messages'), min: @min
          elsif @max
            format I18n.t(:length_max, scope: 'grape.errors.messages'), max: @max
          else
            format I18n.t(:length_is, scope: 'grape.errors.messages'), is: @is
          end
        end
      end
    end
  end
end
