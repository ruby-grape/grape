# frozen_string_literal: true

describe Grape::Parser do
  subject { described_class }

  describe '.parser_for' do
    let(:options) { {} }

    it 'returns parser correctly' do
      expect(subject.parser_for(:json)).to eq(Grape::Parser::Json)
    end

    context 'when parser is available' do
      let(:parsers) do
        { customized_json: Grape::Parser::Json }
      end

      it 'returns registered parser if available' do
        expect(subject.parser_for(:customized_json, parsers)).to eq(Grape::Parser::Json)
      end
    end

    context 'when parser does not exist' do
      it 'returns nil' do
        expect(subject.parser_for(:undefined)).to be_nil
      end
    end
  end
end
