# frozen_string_literal: true

describe Grape::Validations::Types::VariantCollectionCoercer do
  describe '#to_s' do
    it 'renders an Array type as Array[...]' do
      coercer = described_class.new([Integer, String])
      expect(coercer.to_s).to eq('Array[Integer, String]')
    end

    it 'renders a Set type as Set[...]' do
      coercer = described_class.new(Set[Integer, String])
      expect(coercer.to_s).to eq('Set[Integer, String]')
    end
  end

  describe '#call' do
    it 'returns nil for a non-Array value' do
      coercer = described_class.new([Integer, String])
      expect(coercer.call('not an array')).to be_nil
    end

    it 'coerces each member via the member coercer when no method is given' do
      coercer = described_class.new([Integer, String])
      expect(coercer.call(%w[1 abc])).to eq([1, 'abc'])
    end

    it 'coerces the whole collection via the given method' do
      method = ->(value) { value.map(&:upcase) }
      coercer = described_class.new([String], method)
      expect(coercer.call(%w[a b])).to eq(%w[A B])
    end

    it 'returns a Set when the declared types are a Set' do
      coercer = described_class.new(Set[Integer, String])
      expect(coercer.call(%w[1 abc])).to eq(Set[1, 'abc'])
    end
  end
end
