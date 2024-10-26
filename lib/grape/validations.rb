# frozen_string_literal: true

module Grape
  module Validations
    module_function

    def require_validator(short_name)
      ValidatorsRegistry[short_name]
    rescue NameError
      raise Grape::Exceptions::UnknownValidator, short_name
    end

    class ValidatorsRegistry < Grape::Util::Cache
      def initialize
        super
        @cache = Hash.new do |h, name|
          h[name] = Grape::Validations::Validators.const_get(:"#{name.to_s.camelize}Validator")
        end
      end
    end
  end
end
