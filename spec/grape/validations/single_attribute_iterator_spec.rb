require 'spec_helper'

describe Grape::Validations::SingleAttributeIterator do
  describe '#each' do
    subject(:iterator) { described_class.new(validator, scope, params) }
    let(:scope) { Grape::Validations::ParamsScope.new(api: Class.new(Grape::API)) }
    let(:validator) { double(attrs: %i[first second third]) }

    context 'when params is a hash' do
      let(:params) do
        { first: 'string', second: 'string' }
      end

      it 'yields params and every single attribute from the list' do
        expect { |b| iterator.each(&b) }
          .to yield_successive_args([params, :first], [params, :second], [params, :third])
      end
    end

    context 'when params is an array' do
      let(:params) do
        [{ first: 'string1', second: 'string1' }, { first: 'string2', second: 'string2' }]
      end

      it 'yields every single attribute from the list for each of the array elements' do
        expect { |b| iterator.each(&b) }.to yield_successive_args(
          [params[0], :first], [params[0], :second], [params[0], :third],
          [params[1], :first], [params[1], :second], [params[1], :third]
        )
      end
    end
  end
end
