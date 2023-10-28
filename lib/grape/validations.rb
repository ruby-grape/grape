# frozen_string_literal: true

module Grape
  # Registry to store and locate known Validators.
  module Validations
    module_function

    # Find a validator and if not found will try to load it
    def require_validator(short_name)
      Grape::Validations::Validators.const_get("#{short_name.to_s.camelize}Validator")
    rescue NameError
      raise Grape::Exceptions::UnknownValidator.new(short_name)
    end
  end
end
