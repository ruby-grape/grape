module Grape
  module Validations
    class ValidatorFactory
      def initialize(**options)
        @validator_class = options.delete(:validator_class)
        @options         = options
      end

      def create_validator
        @validator_class.new(@options[:attributes],
                             @options[:options],
                             @options[:required],
                             @options[:params_scope],
                             @options[:opts])
      end
    end
  end
end
