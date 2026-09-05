# frozen_string_literal: true

describe Grape::Util::Lazy::ValueEnumerable do
  describe '#[]=' do
    it 'wraps a Hash value in a ValueHash' do
      value_array = Grape::Util::Lazy::ValueArray.new([{ a: 1 }])
      expect(value_array[0]).to be_a(Grape::Util::Lazy::ValueHash)
    end

    it 'wraps an Array value in a ValueArray' do
      value_array = Grape::Util::Lazy::ValueArray.new([[1, 2]])
      expect(value_array[0]).to be_a(described_class)
    end

    it 'wraps any other value in a plain Value' do
      value_array = Grape::Util::Lazy::ValueArray.new([1])
      expect(value_array[0]).to be_a(Grape::Util::Lazy::Value)
    end
  end

  describe '#fetch' do
    it 'reduces a list of access keys down to the reached node' do
      value_hash = Grape::Util::Lazy::ValueHash.new(a: { b: 1 })
      expect(value_hash.fetch(%i[a b]).evaluate).to eq(1)
    end
  end
end
