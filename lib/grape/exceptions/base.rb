module Grape
  module Exceptions
    class Base < StandardError
      BASE_MESSAGES_KEY = 'grape.errors.messages'.freeze
      BASE_ATTRIBUTES_KEY = 'grape.errors.attributes'.freeze
      FALLBACK_LOCALE = :en

      attr_reader :status, :message, :headers

      def initialize(status: nil, message: nil, headers: nil, **_options)
        @status  = status
        @message = message
        @headers = headers
      end

      def [](index)
        send index
      end

      protected

      # TODO: translate attribute first
      # if BASE_ATTRIBUTES_KEY.key respond to a string message, then short_message is returned
      # if BASE_ATTRIBUTES_KEY.key respond to a Hash, means it may have problem , summary and resolution
      def compose_message(key, **attributes)
        short_message = translate_message(key, **attributes)
        if short_message.is_a? Hash
          @problem = problem(key, **attributes)
          @summary = summary(key, **attributes)
          @resolution = resolution(key, **attributes)
          [['Problem', @problem], ['Summary', @summary], ['Resolution', @resolution]].reduce('') do |message, detail_array|
            message << "\n#{detail_array[0]}:\n  #{detail_array[1]}" unless detail_array[1].blank?
            message
          end
        else
          short_message
        end
      end

      def problem(key, attributes)
        translate_message("#{key}.problem".to_sym, attributes)
      end

      def summary(key, attributes)
        translate_message("#{key}.summary".to_sym, attributes)
      end

      def resolution(key, attributes)
        translate_message("#{key}.resolution".to_sym, attributes)
      end

      def translate_attributes(keys, **options)
        keys.map do |key|
          translate("#{BASE_ATTRIBUTES_KEY}.#{key}", default: key, **options)
        end.join(', ')
      end

      def translate_attribute(key, **options)
        translate("#{BASE_ATTRIBUTES_KEY}.#{key}", default: key, **options)
      end

      def translate_message(key, **options)
        case key
        when Symbol
          translate("#{BASE_MESSAGES_KEY}.#{key}", default: '', **options)
        when Proc
          key.call
        else
          key
        end
      end

      def translate(key, **options)
        message = ::I18n.translate(key, **options)
        message.present? ? message : ::I18n.translate(key, locale: FALLBACK_LOCALE, **options)
      end
    end
  end
end
