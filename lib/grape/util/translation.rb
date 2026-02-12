# frozen_string_literal: true

module Grape
  module Util
    module Translation
      FALLBACK_LOCALE = :en
      MISSING = Object.new.freeze
      private_constant :MISSING

      private

      # Extra keyword args (**) are forwarded to I18n as interpolation variables
      # (e.g. min:, max: from LengthValidator's Hash message).
      def translate(key, default: MISSING, scope: nil, locale: nil, **)
        message = ::I18n.translate(key, default:, scope:, locale:, **)
        return message unless message.equal?(MISSING)

        effective_default = default.equal?(MISSING) ? [*Array(scope), key].join('.') : default
        return effective_default if ::I18n.locale == FALLBACK_LOCALE

        if ::I18n.enforce_available_locales && !::I18n.available_locales.include?(FALLBACK_LOCALE)
          effective_default
        else
          ::I18n.translate(key, default: effective_default, scope:, locale: FALLBACK_LOCALE, **)
        end
      end
    end
  end
end
