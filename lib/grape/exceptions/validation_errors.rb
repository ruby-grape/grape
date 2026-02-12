# frozen_string_literal: true

module Grape
  module Exceptions
    class ValidationErrors < Base
      include Enumerable

      attr_reader :errors

      def initialize(errors: [], headers: {})
        @errors = errors.group_by(&:params)
        super(message: full_messages.join(', '), status: 400, headers: headers)
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

      def to_json(*_opts)
        as_json.to_json
      end

      def full_messages
        messages = map do |attributes, error|
          translate(
            :format,
            scope: 'grape.errors',
            default: '%<attributes>s %<message>s',
            attributes: translate_attributes(attributes),
            message: error.message
          )
        end
        messages.uniq!
        messages
      end
    end
  end
end
