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
        return translate_from_snapshot(key, default:, scope:, **) if Grape.ractor?

        i18n_opts = { default:, scope:, ** }
        i18n_opts[:locale] = locale if locale
        message = ::I18n.translate(key, **i18n_opts)
        return message unless message.equal?(MISSING)

        effective_default = default.equal?(MISSING) ? [*Array(scope), key].join('.') : default
        return effective_default if fallback_locale?(locale) || fallback_locale_unavailable?

        ::I18n.translate(key, default: effective_default, scope:, locale: FALLBACK_LOCALE, **)
      end

      # Ractor mode answers from the frozen translations taken when the process
      # was finalized (see Grape::Util::Shareable), because I18n keeps its
      # configuration in class variables, which a non-main Ractor may not read.
      # The locale is the one that was default at that moment: choosing one per
      # request is what this trades away.
      def translate_from_snapshot(key, default:, scope:, **)
        path = Array(scope).flat_map { |part| part.to_s.split('.') }.push(*key.to_s.split('.')).map!(&:to_sym)
        message = Grape::Util::Shareable.translations&.dig(*path)
        message = default.equal?(MISSING) ? path.join('.') : default if message.nil?
        interpolate(message, **)
      end

      # I18n accepts a message with either +%{name}+ or +%<name>s+ placeholders
      # and fills both; Ruby's format only knows the second, so the first is
      # rewritten into it.
      def interpolate(message, **options)
        return message unless message.is_a?(String) && options.any? && message.match?(/%[{<]/)

        format(message.gsub(/%\{(\w+)\}/) { "%<#{::Regexp.last_match(1)}>s" }, **options)
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
