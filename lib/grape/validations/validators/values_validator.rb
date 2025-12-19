# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class ValuesValidator < Base
        def initialize(attrs, options, required, scope, opts)
          @values = options.is_a?(Hash) ? options[:value] : options
          super
        end

        def validate_param!(attr_name, params)
          return unless params.is_a?(Hash)

          val = params[attr_name]

          return if val.nil? && !required_for_root_scope?

          val = val.scrub if val.respond_to?(:valid_encoding?) && !val.valid_encoding?

          # don't forget that +false.blank?+ is true
          return if val != false && val.blank? && @allow_blank

          return if check_values?(val, attr_name)

          raise Grape::Exceptions::Validation.new(
            params: [@scope.full_name(attr_name)],
            message: message(:values)
          )
        end

        private

        def check_values?(val, attr_name)
          values = @values.is_a?(Proc) && @values.arity.zero? ? @values.call : @values
          return true if values.nil?

          param_array = val.nil? ? [nil] : Array.wrap(val)
          return param_array.all? { |param| values.include?(param) } unless values.is_a?(Proc)

          begin
            param_array.all? { |param| values.call(param) }
          rescue StandardError => e
            warn "Error '#{e}' raised while validating attribute '#{attr_name}'"
            false
          end
        end

        def required_for_root_scope?
          return false unless @required

          scope = @scope
          scope = scope.parent while scope.lateral?

          scope.root?
        end
      end
    end
  end
end
