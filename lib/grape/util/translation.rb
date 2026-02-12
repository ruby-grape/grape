# frozen_string_literal: true

module Grape
  module Util
    module Translation
      FALLBACK_LOCALE = :en

      private

      def translate(key, default: '', scope: nil, **)
        message = ::I18n.translate(key, default:, scope:, **)
        return message if message.present?

        if ::I18n.enforce_available_locales && !::I18n.available_locales.include?(FALLBACK_LOCALE)
          scope ? "#{scope}.#{key}" : key
        else
          ::I18n.translate(key, default:, scope:, locale: FALLBACK_LOCALE, **)
        end
      end
    end
  end
end
