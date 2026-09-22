# frozen_string_literal: true

module Grape
  module Translator
    # Resolves through the i18n gem, as Grape always has: at request time, so
    # that the locale in force and any translation the application has loaded
    # over Grape's own both apply.
    #
    # NOTE: every reference to the gem below is spelled +::I18n+. A bare +I18n+
    # inside this module finds this one.
    module I18n
      class << self
        # Extra keyword args are forwarded verbatim to I18n as interpolation
        # variables (e.g. +min:+, +max:+ from LengthValidator's Hash message),
        # so a caller must not pass unintended keywords.
        def call(key, default: MISSING, scope: 'grape.errors.messages', locale: nil, **)
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

        private

        def fallback_locale?(locale)
          (locale || ::I18n.locale) == FALLBACK_LOCALE
        end

        def fallback_locale_unavailable?
          ::I18n.enforce_available_locales && !::I18n.available_locales.include?(FALLBACK_LOCALE)
        end
      end
    end
  end
end
