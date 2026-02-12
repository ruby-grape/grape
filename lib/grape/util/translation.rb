# frozen_string_literal: true

module Grape
  module Util
    module Translation
      FALLBACK_LOCALE = :en
      MISSING = Object.new.freeze
      private_constant :MISSING

      private

      def translate(key, default: '', scope: nil, **)
        message = ::I18n.translate(key, default: MISSING, scope:, **)
        return message unless message.equal?(MISSING)
        return default if ::I18n.locale == FALLBACK_LOCALE

        if ::I18n.enforce_available_locales && !::I18n.available_locales.include?(FALLBACK_LOCALE)
          key.to_s
        else
          ::I18n.translate(key, default:, scope:, locale: FALLBACK_LOCALE, **)
        end
      end
    end
  end
end
