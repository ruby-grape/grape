# frozen_string_literal: true

describe Grape::Validations::Types::ArrayCoercer do
  subject { described_class.new(type) }

  describe '#call' do
    context 'an array of primitives' do
      let(:type) { Array[String] }

      it 'coerces elements in the array' do
        expect(subject.call([10, 20])).to eq(%w[10 20])
      end
    end

    context 'an array of arrays' do
      let(:type) { Array[Array[Integer]] }

      it 'coerces elements in the nested array' do
        expect(subject.call([%w[10 20]])).to eq([[10, 20]])
        expect(subject.call([['10'], ['20']])).to eq([[10], [20]])
      end
    end

    context 'an array of sets' do
      let(:type) { Array[Set[Integer]] }

      it 'coerces elements in the nested set' do
        expect(subject.call([%w[10 20]])).to eq([Set[10, 20]])
        expect(subject.call([['10'], ['20']])).to eq([Set[10], Set[20]])
      end
    end

    context 'when the instance is frozen' do
      let(:type) { Array[Integer] }

      # Instances are shared across requests (and cached in CoercerCache), so
      # the element coercer must be built eagerly rather than memoized at call
      # time. Freezing the instance proves no lazy ivar is written by #call.
      it 'coerces without creating lazy state' do
        subject.freeze
        expect(subject.call(%w[10 20])).to eq([10, 20])
      end
    end
  end
end
