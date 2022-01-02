# frozen_string_literal: true

describe Grape::Validations::MultipleAttributesIterator do
  describe '#each' do
    subject(:iterator) { described_class.new(validator, scope, params) }

    let(:scope) { Grape::Validations::ParamsScope.new(api: Class.new(Grape::API)) }
    let(:validator) { double(attrs: %i[first second third]) }

    context 'when params is a hash' do
      let(:params) do
        { first: 'string', second: 'string' }
      end

      it 'yields the whole params hash and the skipped flag without the list of attrs' do
        expect { |b| iterator.each(&b) }.to yield_with_args(params, false)
      end
    end

    context 'when params is an array' do
      let(:params) do
        [{ first: 'string1', second: 'string1' }, { first: 'string2', second: 'string2' }]
      end

      it 'yields each element of the array without the list of attrs' do
        expect { |b| iterator.each(&b) }.to yield_successive_args([params[0], false], [params[1], false])
      end
    end

    context 'when params is empty optional placeholder' do
      let(:params) do
        [Grape::DSL::Parameters::EmptyOptionalValue, { first: 'string2', second: 'string2' }]
      end

      it 'yields each element of the array without the list of attrs' do
        expect { |b| iterator.each(&b) }.to yield_successive_args([Grape::DSL::Parameters::EmptyOptionalValue, true], [params[1], false])
      end
    end
  end
end
