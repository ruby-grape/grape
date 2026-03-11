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
  end
end
