# frozen_string_literal: true

describe Grape::Exceptions::Base do
  describe '#to_s' do
    subject { described_class.new(message: message).to_s }

    let(:message) { 'a_message' }

    it { is_expected.to eq(message) }
  end

  describe '#message' do
    subject { described_class.new(message: message).message }

    let(:message) { 'a_message' }

    it { is_expected.to eq(message) }
  end

  describe '#compose_message' do
    subject { described_class.new.__send__(:compose_message, key, **attributes) }

    let(:key) { :invalid_formatter }
    let(:attributes) { { klass: String, to_format: 'xml' } }

    after do
      I18n.enforce_available_locales = true
      I18n.available_locales = %i[en]
      I18n.locale = :en
      I18n.default_locale = :en
      I18n.reload!
    end

    context 'when I18n enforces available locales' do
      before { I18n.enforce_available_locales = true }

      context 'when the fallback locale is available' do
        before do
          I18n.available_locales = %i[de en]
          I18n.default_locale = :de
        end

        it 'returns the translated message' do
          expect(subject).to eq('cannot convert String to xml')
        end
      end

      context 'when the fallback locale is not available' do
        before do
          I18n.available_locales = %i[de jp]
          I18n.locale = :de
          I18n.default_locale = :de
        end

        it 'returns the translation string' do
          expect(subject).to eq("grape.errors.messages.#{key}")
        end
      end
    end

    context 'when I18n does not enforce available locales' do
      before { I18n.enforce_available_locales = false }

      context 'when the fallback locale is available' do
        before { I18n.available_locales = %i[de en] }

        it 'returns the translated message' do
          expect(subject).to eq('cannot convert String to xml')
        end
      end

      context 'when the fallback locale is not available' do
        before { I18n.available_locales = %i[de jp] }

        it 'returns the translated message' do
          expect(subject).to eq('cannot convert String to xml')
        end
      end
    end
  end
end
