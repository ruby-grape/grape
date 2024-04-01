# frozen_string_literal: true

module Grape
  module Validations
    module_function

    def validators
      @validators ||= {}
    end

    # Register a new validator, so it can be used to validate parameters.
    # @param short_name [String] all lower-case, no spaces
    # @param klass [Class] the validator class. Should inherit from
    #   Grape::Validations::Validators::Base.
    def register_validator(short_name, klass)
      validators[short_name] = klass
    end

    def deregister_validator(short_name)
      validators.delete(short_name)
    end

    def require_validator(short_name)
      str_name = short_name.to_s
      validators.fetch(str_name) { Grape::Validations::Validators.const_get(:"#{str_name.camelize}Validator") }
    rescue NameError
      raise Grape::Exceptions::UnknownValidator, short_name
    end
  end
end
