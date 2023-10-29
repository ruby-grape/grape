# frozen_string_literal: true

module Grape
  module Validations
    def self.require_validator(short_name)
      Grape::Validations::Validators.const_get("#{short_name.to_s.camelize}Validator")
    rescue NameError
      raise Grape::Exceptions::UnknownValidator, short_name
    end
  end
end
