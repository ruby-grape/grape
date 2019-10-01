require 'spec_helper'

describe Grape::Validations::AtLeastOneOfValidator do
  describe '#validate!' do
    let(:scope) do
      Struct.new(:opts) do
        def params(arg)
          arg
        end

        def required?; end

        # mimics a method from Grape::Validations::ParamsScope which decides how a parameter must
        # be named in errors
        def full_name(name)
          "food[#{name}]"
        end
      end
    end

    let(:at_least_one_of_params) { %i[beer wine grapefruit] }
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
        expected_params = at_least_one_of_params.map { |p| "food[#{p}]" }

        expect { validator.validate! params }.to raise_error do |error|
          expect(error).to be_a(Grape::Exceptions::Validation)
          expect(error.params).to eq(expected_params)
          expect(error.message).to eq(I18n.t('grape.errors.messages.at_least_one'))
        end
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
