require 'spec_helper'

describe Grape::Validations::MutualExclusionValidator do
  describe '#validate!' do
    let(:scope) do
      Struct.new(:opts) do
        def params(arg)
          arg
        end
      end
    end
    let(:mutually_exclusive_params) { [:beer, :wine, :grapefruit] }
    let(:validator) { described_class.new(mutually_exclusive_params, {}, false, scope.new) }

    context 'when all mutually exclusive params are present' do
      let(:params) { { beer: true, wine: true, grapefruit: true } }

      it 'raises a validation exception' do
        expect do
          validator.validate! params
        end.to raise_error(Grape::Exceptions::Validation)
      end

      context 'mixed with other params' do
        let(:mixed_params) { params.merge!(other: true, andanother: true) }

        it 'still raises a validation exception' do
          expect do
            validator.validate! mixed_params
          end.to raise_error(Grape::Exceptions::Validation)
        end
      end
    end

    context 'when a subset of mutually exclusive params are present' do
      let(:params) { { beer: true, grapefruit: true } }

      it 'raises a validation exception' do
        expect do
          validator.validate! params
        end.to raise_error(Grape::Exceptions::Validation)
      end
    end

    context 'when params keys come as strings' do
      let(:params) { { 'beer' => true, 'grapefruit' => true } }

      it 'raises a validation exception' do
        expect do
          validator.validate! params
        end.to raise_error(Grape::Exceptions::Validation)
      end
    end

    context 'when no mutually exclusive params are present' do
      let(:params) { { beer: true, somethingelse: true } }

      it 'params' do
        expect(validator.validate!(params)).to eql params
      end
    end
  end
end
