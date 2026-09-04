# frozen_string_literal: true

describe Grape::ErrorFormatter do
  subject { described_class }

  describe '.formatter_for' do
    it 'returns the registered formatter' do
      expect(subject.formatter_for(:json)).to eq(Grape::ErrorFormatter::Json)
    end

    context 'when the API registered one for the format' do
      let(:error_formatters) { { customized_json: Grape::ErrorFormatter::Json } }

      it 'returns it' do
        expect(subject.formatter_for(:customized_json, error_formatters)).to eq(Grape::ErrorFormatter::Json)
      end

      it 'wins over the registry' do
        expect(subject.formatter_for(:txt, { txt: Grape::ErrorFormatter::Json })).to eq(Grape::ErrorFormatter::Json)
      end
    end

    context 'when no formatter is registered for the format' do
      it 'returns nil, leaving the fallback to the caller' do
        expect(subject.formatter_for(:undefined)).to be_nil
      end

      it 'returns nil for a nil format' do
        expect(subject.formatter_for(nil)).to be_nil
      end
    end
  end
end
