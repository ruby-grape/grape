# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class LengthValidator < Base
        def initialize(attrs, options, required, scope, **opts)
          @min = options[:min]
          @max = options[:max]
          @exact = options[:exact]

          super

          raise ArgumentError, 'min must be an integer greater than or equal to zero' if !@min.nil? && (!@min.is_a?(Integer) || @min.negative?)
          raise ArgumentError, 'max must be an integer greater than or equal to zero' if !@max.nil? && (!@max.is_a?(Integer) || @max.negative?)
          raise ArgumentError, "min #{@min} cannot be greater than max #{@max}" if !@min.nil? && !@max.nil? && @min > @max

          return if @exact.nil?
          raise ArgumentError, 'exact must be an integer greater than zero' if !@exact.is_a?(Integer) || !@exact.positive?
          raise ArgumentError, 'exact cannot be combined with min or max' if !@min.nil? || !@max.nil?
        end

        def validate_param!(attr_name, params)
          param = params[attr_name]

          return unless param.respond_to?(:length)

          return unless (!@min.nil? && param.length < @min) || (!@max.nil? && param.length > @max) || (!@exact.nil? && param.length != @exact)

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
            format I18n.t(:length_exact, scope: 'grape.errors.messages'), exact: @exact
          end
        end
      end
    end
  end
end
