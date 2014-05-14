require 'grape/validations/params_scope'
module Grape
  module Validations
    class << self
      attr_accessor :validators
    end

    self.validators = {}

    def self.register_validator(short_name, klass)
      validators[short_name] = klass
    end

    # This module is mixed into the API Class.
    module ClassMethods
      def reset_validations!
        settings.peek[:declared_params] = []
        settings.peek[:validations] = []
      end

      def params(&block)
        ParamsScope.new(api: self, type: Hash, &block)
      end

      def document_attribute(names, opts)
        @last_description ||= {}
        @last_description[:params] ||= {}
        Array(names).each do |name|
          @last_description[:params][name[:full_name].to_s] ||= {}
          @last_description[:params][name[:full_name].to_s].merge!(opts)
        end
      end
    end
  end
end
# Coerce opens up API, which extends Validations::ClassMethods, above
require 'grape/validations/validators'
