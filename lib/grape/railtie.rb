# frozen_string_literal: true

module Grape
  class Railtie < Rails::Railtie
    if Rails.version.to_f >= 6.0
      initializer 'grape, setup zeitwerk loader for custom validators' do |_app|
        Grape.config.on_unknown_validator << method(:on_grape_unknown_validator) if Rails.autoloaders.zeitwerk_enabled?
      end
    end

    def on_grape_unknown_validator(name)
      validator = ::Grape::Validations::Validators.const_get(name.camelize)

      unless Rails.application.config.eager_load
        # support reloading validators in development
        Rails.autoloaders.main.on_unload(validator.to_s) do
          ::Grape::Validations.deregister_validator(name)
        end
      end

      validator
    rescue NameError
      nil
    end
  end
end
