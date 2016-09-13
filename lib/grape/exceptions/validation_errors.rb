require 'grape/exceptions/base'

module Grape
  module Exceptions
    class ValidationErrors < Grape::Exceptions::Base
      include Enumerable

      attr_reader :errors

      def initialize(errors: [], headers: {}, **_options)
        @errors = {}
        errors.each do |validation_error|
          @errors[validation_error.params] ||= []
          @errors[validation_error.params] << validation_error
        end

        super message: full_messages.join(', '), status: 400, headers: headers
      end

      def each
        errors.each_pair do |attribute, errors|
          errors.each do |error|
            yield attribute, error
          end
        end
      end

      def as_json(**_opts)
        errors.map do |k, v|
          {
            params: k,
            messages: v.map(&:to_s)
          }
        end
      end

      def to_json(**_opts)
        as_json.to_json
      end

      def full_messages
        map { |attributes, error| full_message(attributes, error) }.uniq
      end

      private

      def full_message(attributes, error)
        I18n.t(
          'grape.errors.format'.to_sym,
          default: '%{attributes} %{message}',
          attributes: attributes.count == 1 ? translate_attribute(attributes.first) : translate_attributes(attributes),
          message: error.message
        )
      end
    end
  end
end
