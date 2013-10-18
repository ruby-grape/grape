require 'grape/exceptions/base'

module Grape
  module Exceptions
    class ValidationErrors < Grape::Exceptions::Base
      include Enumerable

      attr_reader :errors

      def initialize(args = {})
        @errors = {}
        args[:errors].each do |validation_error|
          @errors[validation_error.param] ||= []
          @errors[validation_error.param] << validation_error
        end
        super message: full_messages.join(', '), status: 400
      end

      def each
        errors.each_pair do |attribute, errors|
          errors.each do |error|
            yield attribute, error
          end
        end
      end

      private

      def full_messages
        map { |attribute, error| full_message(attribute, error) }
      end

      def full_message(attribute, error)
        I18n.t("grape.errors.format".to_sym, {
          default:  "%{attribute} %{message}",
          attribute: translate_attribute(attribute),
          message:   error.message
        })
      end
    end
  end
end
