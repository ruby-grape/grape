# frozen_string_literal: true

module Grape
  module Exceptions
    class ValidationErrors < Base
      attr_reader :errors

      def initialize(exceptions: [], headers: {})
        @errors = exceptions.flat_map(&:errors).group_by(&:params)
        super(message: full_messages.join(', '), status: 400, headers:)
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
        messages = errors.flat_map do |attributes, errs|
          errs.map do |error|
            translate(
              :format,
              scope: 'grape.errors',
              default: '%<attributes>s %<message>s',
              attributes: translate_attributes(attributes),
              message: error.message
            )
          end
        end
        messages.uniq!
        messages
      end

      private

      def translate_attributes(keys)
        keys.map do |key|
          translate(key, scope: 'grape.errors.attributes', default: key.to_s)
        end.join(', ')
      end
    end
  end
end
