module Grape
  module Validations
    class ValidateService

      def initialize(validators, params)
        @validators = validators
        @params = params
      end

      # api
      def validate!
        @errors = []
        @validators.each do |validator|
          begin
            validator.validate!(params)
          rescue Grape::Exceptions::Validation => e
            @errors << e
          end
        end
        @errors.empty?
      end

      # api
      def params
        clean_params_index(@params)
      end

      # api
      def errors
        @errors ||= []
      end

      private
      def clean_params_index(params)
        case params
        when Array
          params = params.map do |item|
            clean_params_index(item)
          end
        when Hash
          params.delete("_param_index")
          params.each do |key, value|
            params[key] = clean_params_index(value)
          end
        end

        params
      end
    end
  end
end
