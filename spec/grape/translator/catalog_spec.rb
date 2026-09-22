# frozen_string_literal: true

describe Grape::Translator::Catalog do
  subject(:catalog) { described_class.build }

  describe '.build' do
    it 'reads Grape\'s own messages without asking I18n for them' do
      expect(catalog.call(:presence)).to eq('is missing')
    end

    it 'carries the locales I18n has loaded' do
      expect(catalog.locales).to include(:en)
    end

    it 'answers a frozen, shareable table' do
      expect(Ractor.shareable?(catalog)).to be true
    end

    it 'takes the default locale from I18n' do
      expect(catalog.default_locale).to eq(I18n.default_locale)
    end

    it 'carries only the scopes it was asked for' do
      catalog = described_class.build(scopes: %w[nothing_of_ours])
      expect(catalog.call(:presence)).to eq('grape.errors.messages.presence')
    end
  end

  describe '#call' do
    it 'interpolates' do
      expect(catalog.call(:length_min, min: 3)).to eq('is expected to have length greater than or equal to 3')
    end

    it 'reads a nested key' do
      expect(catalog.call(:'invalid_accept_header.problem')).to eq('invalid accept header')
    end

    it 'reads another scope' do
      expect(catalog.call(:format, scope: 'grape.errors', attributes: 'name', message: 'is missing')).to eq('name is missing')
    end

    it 'answers the key path when nothing is found and no default was named' do
      expect(catalog.call(:no_such_message)).to eq('grape.errors.messages.no_such_message')
    end

    it 'answers the default when one was named, interpolating it' do
      expect(catalog.call(:no_such_message, default: 'fallback %<value>s', value: 7)).to eq('fallback 7')
    end
  end

  describe 'the locale in force' do
    around do |example|
      # Two traps: storing before the backend has read its load path is undone
      # by it, and a store for a locale outside available_locales is dropped
      # without a word when enforcement is on.
      I18n.backend.__send__(:init_translations) unless I18n.backend.initialized?
      available = I18n.available_locales_initialized? ? I18n.available_locales : nil
      I18n.available_locales = (available || I18n.available_locales) | %i[es]
      I18n.backend.store_translations(:es, grape: { errors: { messages: { presence: 'falta' } } })
      example.run
    ensure
      Grape.locale = nil
      I18n.available_locales = available
      I18n.backend.reload!
    end

    it 'answers in the locale Grape.locale names' do
      Grape.locale = :es
      expect(catalog.call(:presence)).to eq('falta')
    end

    it 'falls back to English for a locale it does not carry' do
      Grape.locale = :de
      expect(catalog.call(:presence)).to eq('is missing')
    end

    it 'answers in the locale the caller names, over Grape.locale' do
      Grape.locale = :es
      expect(catalog.call(:presence, locale: :en)).to eq('is missing')
    end

    # Fiber storage is inherited by a fiber's children, which is what a
    # request wants, but a write inside one stays there.
    it 'keeps a locale set inside a fiber from leaking back out of it' do
      Grape.locale = :es
      Fiber.new { Grape.locale = :en }.resume
      expect(Grape.locale).to eq(:es)
    end
  end

  # The two translators answer the same lookups, so that swapping one for the
  # other cannot change a message. Every key Grape ships is compared, with a
  # value supplied for each placeholder the message carries.
  describe 'agreeing with the I18n translator' do
    def each_message(tree, prefix = 'grape', &block)
      tree.each do |key, value|
        path = "#{prefix}.#{key}"
        value.is_a?(Hash) ? each_message(value, path, &block) : yield(path, value)
      end
    end

    it 'answers every message the same way' do
      messages = YAML.load_file(File.expand_path('../../../lib/grape/locale/en.yml', __dir__)).dig('en', 'grape')
      compared = 0

      each_message(messages) do |path, template|
        scope, _, key = path.rpartition('.')
        options = template.scan(/%\{(\w+)\}/).flatten.to_h { |name| [name.to_sym, "<#{name}>"] }

        expect(catalog.call(key, scope:, **options))
          .to eq(Grape::Translator::I18n.call(key, scope:, **options)), "#{path} differs"
        compared += 1
      end

      expect(compared).to be > 30
    end
  end
end
