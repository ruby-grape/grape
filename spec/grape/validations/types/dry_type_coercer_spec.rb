# frozen_string_literal: true

describe Grape::Validations::Types::DryTypeCoercer do
  describe '.collection_coercer_for' do
    it 'returns ArrayCoercer for an Array instance' do
      expect(described_class.collection_coercer_for([])).to eq(Grape::Validations::Types::ArrayCoercer)
    end

    it 'returns SetCoercer for a Set instance' do
      expect(described_class.collection_coercer_for(Set.new)).to eq(Grape::Validations::Types::SetCoercer)
    end

    it 'raises an ArgumentError for any other type' do
      expect { described_class.collection_coercer_for({}) }.to raise_error(ArgumentError, /Unknown type/)
    end
  end
end
