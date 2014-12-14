require 'spec_helper'

describe Grape::Validations::AtLeastOneOfValidator do
  describe '#validate!' do
    let(:scope) do
      Struct.new(:opts) do
        def params(arg)
          arg
        end

        def required?; end
      end
    end
    let(:at_least_one_of_params) { [:beer, :wine, :grapefruit] }
    let(:validator) { described_class.new(at_least_one_of_params, {}, false, scope.new) }

    context 'when all restricted params are present' do
      let(:params) { { beer: true, wine: true, grapefruit: true } }

      it 'does not raise a validation exception' do
        expect(validator.validate!(params)).to eql params
      end

      context 'mixed with other params' do
        let(:mixed_params) { params.merge!(other: true, andanother: true) }

        it 'does not raise a validation exception' do
          expect(validator.validate!(mixed_params)).to eql mixed_params
        end
      end
    end

    context 'when a subset of restricted params are present' do
      let(:params) { { beer: true, grapefruit: true } }

      it 'does not raise a validation exception' do
        expect(validator.validate!(params)).to eql params
      end
    end

    context 'when params keys come as strings' do
      let(:params) { { 'beer' => true, 'grapefruit' => true } }

      it 'does not raise a validation exception' do
        expect(validator.validate!(params)).to eql params
      end
    end

    context 'when none of the restricted params is selected' do
      let(:params) { { somethingelse: true } }

      it 'raises a validation exception' do
        expect do
          validator.validate! params
        end.to raise_error(Grape::Exceptions::Validation)
      end
    end

    context 'when exactly one of the restricted params is selected' do
      let(:params) { { beer: true, somethingelse: true } }

      it 'does not raise a validation exception' do
        expect(validator.validate!(params)).to eql params
      end
    end
  end
end
