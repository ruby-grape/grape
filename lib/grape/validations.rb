# frozen_string_literal: true

require 'grape/validations/attributes_iterator'
require 'grape/validations/single_attribute_iterator'
require 'grape/validations/multiple_attributes_iterator'
require 'grape/validations/params_scope'
require 'grape/validations/types'

module Grape
  # Registry to store and locate known Validators.
  module Validations
    module_function

    def validators
      @validators ||= {}
    end

    # Register a new validator, so it can be used to validate parameters.
    # @param short_name [String] all lower-case, no spaces
    # @param klass [Class] the validator class. Should inherit from
    #   Validations::Base.
    def register_validator(short_name, klass)
      validators[short_name] = klass
    end

    def deregister_validator(short_name)
      validators.delete(short_name)
    end

    # Find a validator and if not found will try to load it
    def lazy_find_validator(short_name)
      str_name = short_name.to_s
      validators.fetch(str_name) do
        register_validator(str_name, "Grape::Validations::Validators::#{str_name.camelize}Validator".constantize)
      end
    rescue NameError
      raise Grape::Exceptions::UnknownValidator.new(short_name)
    end
  end
end
