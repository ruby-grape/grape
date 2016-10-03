require 'spec_helper'

describe Grape::Validations::AllOrNoneOfValidator do
  describe '#validate!' do
    let(:scope) do
      Struct.new(:opts) do
        def params(arg)
          arg
        end

        def required?; end
      end
    end
    let(:all_or_none_params) { [:beer, :wine, :grapefruit] }
    let(:validator) { described_class.new(all_or_none_params, {}, false, scope.new) }

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

    context 'when none of the restricted params is selected' do
      let(:params) { { somethingelse: true } }

      it 'does not raise a validation exception' do
        expect(validator.validate!(params)).to eql params
      end
    end

    context 'when only a subset of restricted params are present' do
      let(:params) { { beer: true, grapefruit: true } }

      it 'raises a validation exception' do
        expect do
          validator.validate! params
        end.to raise_error(Grape::Exceptions::Validation)
      end
      context 'mixed with other params' do
        let(:mixed_params) { params.merge!(other: true, andanother: true) }

        it 'raise a validation exception' do
          expect do
            validator.validate! params
          end.to raise_error(Grape::Exceptions::Validation)
        end
      end
    end
  end
end
