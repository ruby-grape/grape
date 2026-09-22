# frozen_string_literal: true

module Grape
  # Where Grape's error messages come from. {Grape::Util::Translation#translate}
  # hands every lookup to +Grape.translator+, which answers it:
  #
  # * {Translator::I18n}, the default, asks I18n at request time, so a
  #   per-request locale and an application's own overrides both apply.
  # * {Translator::Catalog} answers from a table built once, which is faster,
  #   needs no I18n at all, and can be read from a non-main Ractor.
  #
  # A translator is anything answering +call+ with this signature; the two
  # here are the ones Grape ships.
  module Translator
    FALLBACK_LOCALE = :en

    # Stands for "the caller named no default", so that nil and false can be
    # defaults in their own right. Its +inspect+ names it in debug output.
    MISSING = Class.new { def inspect = 'Grape::Translator::MISSING' }.new.freeze
  end
end
