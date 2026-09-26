# frozen_string_literal: true

describe Grape::Validations::AttributesIterator do
  describe '#each' do
    subject(:iterator) { described_class.new(scope) }

    let(:scope) { Grape::Validations::ParamsScope.new(api: Class.new(Grape::API)) }

    context 'when params is a hash' do
      let(:params) do
        { first: 'string', second: 'string' }
      end

      it 'yields the whole params hash once' do
        expect { |b| iterator.each(params, &b) }.to yield_successive_args(params)
      end
    end

    context 'when params is an array' do
      let(:params) do
        [{ first: 'string1', second: 'string1' }, { first: 'string2', second: 'string2' }]
      end

      it 'yields each element of the array, not as an element of its own' do
        expect { |b| iterator.each(params, &b) }.to yield_successive_args([params[0], false], [params[1], false])
      end
    end

    context 'when an element is the empty optional placeholder' do
      let(:params) { [Grape::DSL::Parameters::EmptyOptionalValue, 10] }

      it 'does not yield it' do
        expect { |b| iterator.each(params, &b) }.to yield_successive_args([params[1], false])
      end
    end
  end
end
