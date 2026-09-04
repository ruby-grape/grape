# frozen_string_literal: true

describe Grape::Util::Translation do
  subject(:translator) do
    Class.new do
      include Grape::Util::Translation

      def translate_message(key, **opts)
        translate(key, **opts)
      end
    end.new
  end

  describe '#translate_message' do
    context 'when the translation value uses a reserved I18n interpolation key' do
      around do |example|
        I18n.backend.store_translations(:en, grape: { errors: { messages: { reserved_key_test: 'value %{scope}' } } }) # rubocop:disable Style/FormatStringToken
        example.run
      ensure
        I18n.reload!
      end

      it 'raises I18n::ReservedInterpolationKey' do
        expect { translator.translate_message(:reserved_key_test) }.to raise_error(I18n::ReservedInterpolationKey)
      end
    end

    context 'when an explicit locale is given' do
      it 'passes the locale through to I18n.translate' do
        expect(I18n).to receive(:translate).with(:missing_key, hash_including(locale: :en)).and_call_original
        translator.translate_message(:missing_key, locale: :en)
      end
    end

    context 'when an explicit default is given and the key is missing' do
      it 'returns the given default instead of the dotted key path' do
        expect(translator.translate_message(:missing_key, default: 'fallback')).to eq('fallback')
      end
    end

    context 'when no default is given and the key is missing' do
      it 'returns the dotted scope+key path as the default' do
        expect(translator.translate_message(:missing_key)).to eq('grape.errors.messages.missing_key')
      end
    end

    context 'when a non-fallback locale is given, is available, and the key is missing there too' do
      around do |example|
        I18n.available_locales = %i[en fr]
        example.run
      ensure
        I18n.available_locales = %i[en]
      end

      it 're-attempts translation against the fallback locale' do
        expect(I18n).to receive(:translate).with(:missing_key, hash_including(locale: :fr)).and_call_original
        expect(I18n).to receive(:translate).with(:missing_key, hash_including(locale: :en)).and_call_original
        translator.translate_message(:missing_key, locale: :fr)
      end

      it 'forwards an explicit default to the fallback-locale retry' do
        expect(translator.translate_message(:missing_key, locale: :fr, default: 'fallback')).to eq('fallback')
      end
    end
  end
end
