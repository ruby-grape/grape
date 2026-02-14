# frozen_string_literal: true

module Grape
  module Validations
    extend Grape::Util::Registry

    module_function

    def require_validator(short_name, scope: nil)
      return registry[short_name] if registry.key?(short_name)

      custom_klass = find_custom_validator_in_scope(short_name, scope) if scope
      return custom_klass if custom_klass

      raise Grape::Exceptions::UnknownValidator, short_name
    end

    # Tries to resolve a custom validator constant in the API's namespace.
    # Convention: for API class Api::V2::Jobs and short_name :uuid, looks up
    # Api::V2::Validators::Uuid. This allows custom validators to be used
    # without explicit require and without polluting the global validator registry.
    # When +scope+ is a Grape mount instance (anonymous class), uses its +@base+ to
    # resolve the named API class for constant lookup.
    def find_custom_validator_in_scope(short_name, scope)
      api_class = resolve_api_class(scope)
      return unless api_class&.name.present?

      namespace = api_class.module_parent
      return if namespace == Object

      class_name = short_name.to_s.camelize
      validators_mod = namespace.const_get(:Validators)
      klass = validators_mod.const_get(class_name)
      return unless klass.is_a?(Class)
      return unless klass <= Grape::Validations::Validators::Base

      klass
    rescue NameError
      nil
    end

    def resolve_api_class(scope)
      if scope.instance_variable_defined?(:@base)
        scope.instance_variable_get(:@base)
      elsif scope.is_a?(Module)
        scope
      else
        scope.class
      end
    end

    def build_short_name(klass)
      return if klass.name.blank?

      klass.name.demodulize.underscore.delete_suffix('_validator')
    end
  end
end
