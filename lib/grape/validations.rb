# frozen_string_literal: true

module Grape
  module Validations
    extend Grape::Util::Registry

    module_function

    def require_validator(short_name, api_class: nil)
      return registry[short_name] if registry.key?(short_name)

      klass = find_validator_in_namespace(short_name, api_class) if api_class
      raise Grape::Exceptions::UnknownValidator, short_name unless klass

      klass
    end

    def find_validator_in_namespace(short_name, api_class)
      const_name = short_name.to_s.camelize
      lookup_class = api_class
      lookup_class = lookup_class.superclass while lookup_class && lookup_class.name.blank?
      name = lookup_class&.name
      return nil if name.blank?

      parent_name = name.rpartition('::').first
      return nil if parent_name.blank?

      namespace = Object.const_get(parent_name)
      while namespace.is_a?(Module) && namespace != Object
        if namespace.const_defined?(:Validators, false)
          validators_mod = namespace.const_get(:Validators)
          if validators_mod.const_defined?(const_name, false)
            klass = validators_mod.const_get(const_name)
            return klass if klass.is_a?(Class) && klass < Validators::Base
          end
        end
        parent_name = namespace.name.rpartition('::').first
        break if parent_name.blank?

        namespace = Object.const_get(parent_name)
      end
      nil
    end

    def build_short_name(klass)
      return if klass.name.blank?

      klass.name.demodulize.underscore.delete_suffix('_validator')
    end
  end
end
