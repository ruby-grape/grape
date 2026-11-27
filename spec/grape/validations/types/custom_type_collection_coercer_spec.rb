# frozen_string_literal: true

describe Grape::Validations::Types::CustomTypeCollectionCoercer do
  let(:custom_type) do
    Class.new do
      def self.parse(value) = "#{value}haha"
      def self.parsed?(value) = value.is_a?(String)
    end
  end

  describe '#call' do
    context 'with an array of a custom type' do
      subject { described_class.new(custom_type) }

      it 'coerces each item' do
        expect(subject.call([1, 2])).to eq(%w[1haha 2haha])
      end

      it 'accepts a set and an empty collection' do
        expect(subject.call(Set[1, 2])).to eq(%w[1haha 2haha])
        expect(subject.call([])).to eq([])
        expect(subject.call(Set.new)).to eq([])
      end

      it 'returns an InvalidValue for a value that is not an Array or a Set' do
        [nil, '', '1', 1, false, { a: 1 }, 1..2, [1].each].each do |value|
          expect(subject.call(value)).to be_a(Grape::Validations::Types::InvalidValue), "expected #{value.inspect} to be invalid"
        end
      end

      it 'returns an InvalidValue when an item cannot be parsed' do
        parser = Class.new do
          def self.parse(value) = value == 'bad' ? Grape::Validations::Types::InvalidValue.new : value.to_s
          def self.parsed?(value) = value.is_a?(String)
        end

        expect(described_class.new(parser).call(%w[1 bad])).to be_a(Grape::Validations::Types::InvalidValue)
      end
    end

    context 'with a set of a custom type' do
      subject { described_class.new(custom_type, set: true) }

      it 'returns a set' do
        expect(subject.call([1, 1])).to eq(Set['1haha'])
      end
    end
  end
end
