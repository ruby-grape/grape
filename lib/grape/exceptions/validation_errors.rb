# frozen_string_literal: true

module Grape
  module Exceptions
    class ValidationErrors < Base
      ERRORS_FORMAT_KEY = 'grape.errors.format'
      DEFAULT_ERRORS_FORMAT = '%<attributes>s %<message>s'

      attr_reader :errors

      def initialize(errors: [], headers: {})
        @errors = errors.group_by(&:params)
        super(message: full_messages.join(', '), status: 400, headers: headers)
      end

      def each
        return to_enum(:each) unless block_given?

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

      def to_json(*_opts)
        as_json.to_json
      end

      def full_messages
        [].tap do |messages|
          each do |attributes, error|
            messages <<
              I18n.t(ERRORS_FORMAT_KEY,
                     default: DEFAULT_ERRORS_FORMAT,
                     attributes: translate_attributes(attributes),
                     message: error.message)
          end
          messages.uniq!
        end
      end
    end
  end
end
