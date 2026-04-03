# frozen_string_literal: true

describe Grape::Exceptions::Base do
  describe '#to_s' do
    subject { described_class.new(message:).to_s }

    let(:message) { 'a_message' }

    it { is_expected.to eq(message) }
  end

  describe '#message' do
    subject { described_class.new(message:).message }

    let(:message) { 'a_message' }

    it { is_expected.to eq(message) }
  end

  describe '#compose_message' do
    subject { described_class.new.__send__(:compose_message, key, **attributes) }

    let(:key) { :invalid_formatter }
    let(:attributes) { { klass: String, to_format: 'xml' } }

    after { I18n.reload! }

    context 'when I18n enforces available locales' do
      context 'when the fallback locale is available' do
        around do |example|
          I18n.available_locales = %i[de en]
          I18n.with_locale(:de) { example.run }
        ensure
          I18n.available_locales = %i[en]
        end

        it 'returns the translated message' do
          expect(subject).to eq('cannot convert String to xml')
        end
      end

      context 'when the fallback locale is not available' do
        around do |example|
          I18n.available_locales = %i[de jp]
          I18n.with_locale(:de) do
            example.run
          ensure
            I18n.available_locales = %i[en]
          end
        end

        it 'returns the scoped translation key as a string' do
          expect(subject).to eq("grape.errors.messages.#{key}")
        end
      end
    end

    context 'when I18n does not enforce available locales' do
      around do |example|
        I18n.enforce_available_locales = false
        example.run
      ensure
        I18n.enforce_available_locales = true
      end

      context 'when the fallback locale is available' do
        around do |example|
          I18n.available_locales = %i[de en]
          I18n.with_locale(:de) { example.run }
        ensure
          I18n.available_locales = %i[en]
        end

        it 'returns the translated message' do
          expect(subject).to eq('cannot convert String to xml')
        end
      end

      context 'when the fallback locale is not available' do
        around do |example|
          I18n.available_locales = %i[de jp]
          I18n.with_locale(:de) { example.run }
        ensure
          I18n.available_locales = %i[en]
        end

        it 'returns the translated message' do
          expect(subject).to eq('cannot convert String to xml')
        end
      end
    end
  end
end
