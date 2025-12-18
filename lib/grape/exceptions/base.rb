# frozen_string_literal: true

module Grape
  module Exceptions
    class Base < StandardError
      BASE_MESSAGES_KEY = 'grape.errors.messages'
      BASE_ATTRIBUTES_KEY = 'grape.errors.attributes'
      FALLBACK_LOCALE = :en

      attr_reader :status, :headers

      def initialize(status: nil, message: nil, headers: nil)
        super(message)

        @status  = status
        @headers = headers
      end

      def [](index)
        __send__ index
      end

      protected

      # TODO: translate attribute first
      # if BASE_ATTRIBUTES_KEY.key respond to a string message, then short_message is returned
      # if BASE_ATTRIBUTES_KEY.key respond to a Hash, means it may have problem , summary and resolution
      def compose_message(key, **attributes)
        short_message = translate_message(key, attributes)
        return short_message unless short_message.is_a?(Hash)

        each_steps(key, attributes).with_object(+'') do |detail_array, message|
          message << "\n#{detail_array[0]}:\n  #{detail_array[1]}" unless detail_array[1].blank?
        end
      end

      def each_steps(key, attributes)
        return enum_for(:each_steps, key, attributes) unless block_given?

        yield 'Problem', translate_message(:"#{key}.problem", attributes)
        yield 'Summary', translate_message(:"#{key}.summary", attributes)
        yield 'Resolution', translate_message(:"#{key}.resolution", attributes)
      end

      def translate_attributes(keys, options = {})
        keys.map do |key|
          translate("#{BASE_ATTRIBUTES_KEY}.#{key}", options.merge(default: key.to_s))
        end.join(', ')
      end

      def translate_message(key, options = {})
        case key
        when Symbol
          translate("#{BASE_MESSAGES_KEY}.#{key}", options.merge(default: ''))
        when Proc
          key.call
        else
          key
        end
      end

      def translate(key, options)
        message = ::I18n.translate(key, **options)
        message.presence || fallback_message(key, options)
      end

      def fallback_message(key, options)
        if ::I18n.enforce_available_locales && !::I18n.available_locales.include?(FALLBACK_LOCALE)
          key
        else
          ::I18n.translate(key, locale: FALLBACK_LOCALE, **options)
        end
      end
    end
  end
end
