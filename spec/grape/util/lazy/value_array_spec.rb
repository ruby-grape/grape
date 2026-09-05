# frozen_string_literal: true

describe Grape::Util::Lazy::ValueArray do
  describe '#evaluate' do
    it 'evaluates every element of the array' do
      value_array = described_class.new([1, 2, { a: 1 }])
      expect(value_array.evaluate).to eq([1, 2, { 'a' => 1 }])
    end
  end

  describe '#[]' do
    it 'returns the Lazy::Value at the given index' do
      value_array = described_class.new([1, 2])
      expect(value_array[0].evaluate).to eq(1)
    end

    it 'returns a nil Lazy::Value for an out-of-bounds index' do
      value_array = described_class.new([1, 2])
      expect(value_array[10].evaluate).to be_nil
    end
  end
end
