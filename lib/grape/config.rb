require 'json'

module Grape
  class << self
    # Set the configuration options. Best used by passing a block.
    #
    # @example Set up configuration options.
    #   Grape::Config do |config|
    #     config.json_processor = JSON
    #   end
    #
    # @return [Config] The configuration object.
    def configure
      block_given? ? yield(Grape::Config) : Grape::Config
    end
    alias_method :config, :configure
  end

  module Config
    extend self

    # Current configuration settings.
    attr_accessor :settings

    # Default configuration settings.
    attr_accessor :defaults

    @settings = {}
    @defaults = {}

    # Define a configuration option with a default.
    #
    # @example Define the option.
    # Config.option(:json_processor, default: JSON)
    #
    # @param [Symbol] name The name of the configuration option.
    # @param [Hash] options Extras for the option.
    #
    # @option options [Object] :default The default value.
    def option(name, options = {})
      defaults[name] = settings[name] = options[:default]

      class_eval <<-RUBY
        def #{name}
          settings[#{name.inspect}]
        end
        def #{name}=(value)
          settings[#{name.inspect}] = value
        end
        def #{name}?
          #{name}
        end
      RUBY
    end

    # Default json processor options
    option(:json_processor, default: JSON)
  end
end
