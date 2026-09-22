# frozen_string_literal: true

require 'yaml'

module Grape
  module Translator
    # Every message Grape can answer with, in one frozen table built at boot:
    #
    #   { en: { 'grape.errors.messages.presence' => 'is missing', ... }, ... }
    #
    # Flat keys, so a lookup is a single +Hash#[]+, and the interpolation
    # placeholders are rewritten from I18n's <tt>%{name}</tt> into the
    # <tt>%<name>s</tt> that +format+ takes, so answering a message is a
    # lookup and a +format+ rather than a trip through I18n.
    #
    # It reads Grape's own +locale/en.yml+ directly, so it works with I18n
    # absent, and merges whatever I18n has loaded over the top, so an
    # application's overrides and other locales are carried.
    #
    # What it trades away: the table is a snapshot. A locale file loaded after
    # it was built -- lazily, or through +I18n.reload!+ in development -- is
    # not in it. And the locale in force comes from {Grape.locale} rather than
    # from I18n, which cannot be read from a non-main Ractor.
    class Catalog
      OWN_MESSAGES = File.expand_path('../locale/en.yml', __dir__)
      private_constant :OWN_MESSAGES

      # The top-level scopes carried over from I18n. A validator translating
      # from a namespace of its own has to name it here.
      DEFAULT_SCOPES = %w[grape].freeze

      # +default_locale+ is the locale a lookup falls to when nothing named
      # one, and defaults to I18n's at the moment the table is built.
      def self.build(scopes: DEFAULT_SCOPES, default_locale: nil)
        # A plain Hash, with no default block: the table is frozen at the end,
        # and a miss must answer nil rather than try to write an empty locale
        # into it.
        messages = { FALLBACK_LOCALE => {} }
        flatten_into(messages[FALLBACK_LOCALE], YAML.load_file(OWN_MESSAGES).fetch('en'), nil, scopes)
        merge_i18n_into(messages, scopes) if defined?(::I18n)

        new(Grape::Util::DeepFreeze.deep_freeze(messages), default_locale || i18n_default_locale)
      end

      class << self
        private

        def merge_i18n_into(messages, scopes)
          ::I18n.backend.__send__(:init_translations) unless ::I18n.backend.initialized?
          ::I18n.backend.translations.each do |locale, tree|
            flatten_into(messages[locale.to_sym] ||= {}, tree, nil, scopes)
          end
        end

        def i18n_default_locale
          defined?(::I18n) ? ::I18n.default_locale : FALLBACK_LOCALE
        end

        # Walks a locale tree into dotted keys, keeping only the named
        # top-level scopes. A leaf that is not a String -- a Proc in a
        # pluralization rule, say -- is not a message and is left behind.
        def flatten_into(target, tree, prefix, scopes)
          tree.each do |key, value|
            path = prefix ? "#{prefix}.#{key}" : key.to_s
            next if prefix.nil? && !scopes.include?(path)

            case value
            when Hash then flatten_into(target, value, path, scopes)
            when String then target[path] = interpolatable(value)
            end
          end
        end

        # I18n accepts <tt>%{name}</tt> and <tt>%<name>s</tt> alike; +format+
        # only knows the second, so the first is rewritten once, here, rather
        # than on every message.
        def interpolatable(message)
          return message unless message.include?('%{')

          message.gsub(/%\{(\w+)\}/) { "%<#{::Regexp.last_match(1)}>s" }
        end
      end

      attr_reader :default_locale

      def initialize(messages, default_locale)
        @messages = messages
        @default_locale = default_locale
        freeze
      end

      def call(key, default: MISSING, scope: 'grape.errors.messages', locale: nil, **options)
        path = "#{scope}.#{key}"
        message = lookup(path, locale || Grape.locale || @default_locale)
        return interpolate(message, options) if message
        return path if default.equal?(MISSING)

        interpolate(default, options)
      end

      # The locales the table carries, for an application that wants to check
      # what a built catalog knows.
      def locales
        @messages.keys
      end

      private

      def lookup(path, locale)
        @messages.dig(locale, path) || @messages.dig(FALLBACK_LOCALE, path)
      end

      def interpolate(message, options)
        return message unless message.is_a?(String) && options.any? && message.include?('%<')

        format(message, **options)
      end
    end
  end
end
