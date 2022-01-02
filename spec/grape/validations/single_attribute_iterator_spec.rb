# frozen_string_literal: true

describe Grape::Validations::SingleAttributeIterator do
  describe '#each' do
    subject(:iterator) { described_class.new(validator, scope, params) }

    let(:scope) { Grape::Validations::ParamsScope.new(api: Class.new(Grape::API)) }
    let(:validator) { double(attrs: %i[first second]) }

    context 'when params is a hash' do
      let(:params) do
        { first: 'string', second: 'string' }
      end

      it 'yields params and every single attribute from the list' do
        expect { |b| iterator.each(&b) }
          .to yield_successive_args([params, :first, false, false], [params, :second, false, false])
      end
    end

    context 'when params is an array' do
      let(:params) do
        [{ first: 'string1', second: 'string1' }, { first: 'string2', second: 'string2' }]
      end

      it 'yields every single attribute from the list for each of the array elements' do
        expect { |b| iterator.each(&b) }.to yield_successive_args(
          [params[0], :first, false, false], [params[0], :second, false, false],
          [params[1], :first, false, false], [params[1], :second, false, false]
        )
      end

      context 'empty values' do
        let(:params) { [{}, '', 10] }

        it 'marks params with empty values' do
          expect { |b| iterator.each(&b) }.to yield_successive_args(
            [params[0], :first, true, false], [params[0], :second, true, false],
            [params[1], :first, true, false], [params[1], :second, true, false],
            [params[2], :first, false, false], [params[2], :second, false, false]
          )
        end
      end

      context 'when missing optional value' do
        let(:params) { [Grape::DSL::Parameters::EmptyOptionalValue, 10] }

        it 'marks params with skipped values' do
          expect { |b| iterator.each(&b) }.to yield_successive_args(
            [params[0], :first, false, true], [params[0], :second, false, true],
            [params[1], :first, false, false], [params[1], :second, false, false]
          )
        end
      end
    end
  end
end
