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
    it 'returns nil for a nil or empty value' do
      coercer = described_class.new([Integer, String])
      expect([coercer.call(nil), coercer.call('')]).to eq([nil, nil])
    end

    it 'returns an InvalidValue for a non-Array value' do
      coercer = described_class.new([Integer, String])
      expect(coercer.call('not an array')).to be_a(Grape::Validations::Types::InvalidValue)
    end

    it 'coerces each member via the member coercer when no method is given' do
      coercer = described_class.new([Integer, String])
      expect(coercer.call(%w[1 abc])).to eq([1, 'abc'])
    end

    it 'returns an InvalidValue when a member is none of the types' do
      coercer = described_class.new([Integer, String])
      expect(coercer.call([1, {}])).to be_a(Grape::Validations::Types::InvalidValue)
    end

    it 'coerces the whole collection via the given method' do
      method = ->(value) { value.map(&:upcase) }
      coercer = described_class.new([String], method)
      expect(coercer.call(%w[a b])).to eq(%w[A B])
    end

    it 'hands the given method a value that is not an Array' do
      method = ->(value) { value.split(',') }
      coercer = described_class.new([Integer, String], method)
      expect(coercer.call('1,a')).to eq(%w[1 a])
    end

    it 'returns a Set when the declared types are a Set' do
      coercer = described_class.new(Set[Integer, String])
      expect(coercer.call(%w[1 abc])).to eq(Set[1, 'abc'])
    end
  end
end
