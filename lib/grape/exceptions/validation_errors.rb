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

      # Translated once, when the error is built for its #message, and handed
      # out as a copy from then on. Every lookup here is an I18n call of a few
      # microseconds, and the README's recipe for answering with the list,
      # +error!({ messages: e.full_messages }, 400)+, asked for all of them a
      # second time. It also keeps the list the same as #message, which was
      # already fixed at that point, if the locale changes in between.
      def full_messages
        (@full_messages ||= translate_full_messages).dup
      end

      private

      def translate_full_messages
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

      def translate_attributes(keys)
        keys.map do |key|
          translate(key, scope: 'grape.errors.attributes', default: key.to_s)
        end.join(', ')
      end
    end
  end
end
