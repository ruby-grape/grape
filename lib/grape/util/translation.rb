# frozen_string_literal: true

module Grape
  module Util
    # The message lookup every exception and validator reaches for. What
    # answers it is +Grape.translator+ (see Grape::Translator), so an
    # application can swap I18n for a table without any of them changing.
    module Translation
      private

      # Extra keyword args (**) are forwarded verbatim as interpolation
      # variables (e.g. +min:+, +max:+ from LengthValidator's Hash message).
      # Callers must not pass unintended keyword arguments — any extra keyword
      # will silently become an interpolation variable.
      def translate(key, default: Grape::Translator::MISSING, scope: 'grape.errors.messages', locale: nil, **)
        Grape.translator.call(key, default:, scope:, locale:, **)
      end
    end
  end
end
