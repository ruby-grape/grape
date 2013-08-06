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
          @errors[validation_error.param] << validation_error.message
        end
        super message: full_messages.join(', '), status: 400
      end

      def each
        errors.each_pair do |attribute, messages|
          messages.each do |message|
            yield attribute, message
          end
        end
      end

      private

      def full_messages
        map { |attribute, message| full_message(attribute, message) }
      end

      def full_message(attribute, message)
        I18n.t(:"grape.errors.format", {
          default:  "%{attribute} %{message}",
          attribute: translate_attribute(attribute),
          message:   message
        })
      end
    end
  end
end
