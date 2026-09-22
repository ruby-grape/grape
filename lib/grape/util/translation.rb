# frozen_string_literal: true

module Grape
  module Util
    module Translation
      FALLBACK_LOCALE = :en
      private_constant :FALLBACK_LOCALE
      # Sentinel returned by I18n when a key is missing (passed as the default:
      # value). Its +inspect+ names it in debug output.
      MISSING = Class.new { def inspect = 'Grape::Util::Translation::MISSING' }.new.freeze
      private_constant :MISSING

      private

      # Extra keyword args (**) are forwarded verbatim to I18n as interpolation
      # variables (e.g. +min:+, +max:+ from LengthValidator's Hash message).
      # Callers must not pass unintended keyword arguments — any extra keyword
      # will silently become an I18n interpolation variable.
      def translate(key, default: MISSING, scope: 'grape.errors.messages', locale: nil, **)
        i18n_opts = { default:, scope:, ** }
        i18n_opts[:locale] = locale if locale
        message = ::I18n.translate(key, **i18n_opts)
        return message unless message.equal?(MISSING)

        # Only a call without +default:+ gets here: I18n answers any other with
        # that default, so a miss falls back to the key's full path instead.
        scoped_key = [*Array(scope), key].join('.')
        return scoped_key if fallback_locale?(locale) || fallback_locale_unavailable?

        ::I18n.translate(key, default: scoped_key, scope:, locale: FALLBACK_LOCALE, **)
      end

      def fallback_locale?(locale)
        (locale || ::I18n.locale) == FALLBACK_LOCALE
      end

      def fallback_locale_unavailable?
        ::I18n.enforce_available_locales && !::I18n.available_locales.include?(FALLBACK_LOCALE)
      end
    end
  end
end
