# frozen_string_literal: true

describe Grape::Validations::Types::PrimitiveCoercer do
  subject { described_class.new(type, strict) }

  let(:strict) { false }

  describe '#call' do
    context 'BigDecimal' do
      let(:type) { BigDecimal }

      it 'coerces to BigDecimal' do
        expect(subject.call(5)).to eq(BigDecimal('5'))
      end

      it 'coerces an empty string to nil' do
        expect(subject.call('')).to be_nil
      end
    end

    context 'Boolean' do
      let(:type) { Grape::API::Boolean }

      [true, 'true', 1].each do |val|
        it "coerces '#{val}' to true" do
          expect(subject.call(val)).to be(true)
        end
      end

      [false, 'false', 0].each do |val|
        it "coerces '#{val}' to false" do
          expect(subject.call(val)).to be(false)
        end
      end

      it 'returns an error when the given value cannot be coerced' do
        expect(subject.call(123)).to be_instance_of(Grape::Validations::Types::InvalidValue)
      end

      it 'coerces an empty string to nil' do
        expect(subject.call('')).to be_nil
      end
    end

    context 'DateTime' do
      let(:type) { DateTime }

      it 'coerces an empty string to nil' do
        expect(subject.call('')).to be_nil
      end
    end

    context 'Float' do
      let(:type) { Float }

      it 'coerces an empty string to nil' do
        expect(subject.call('')).to be_nil
      end
    end

    context 'Integer' do
      let(:type) { Integer }

      it 'coerces an empty string to nil' do
        expect(subject.call('')).to be_nil
      end

      it 'accepts non-nil value' do
        expect(subject.call(42)).to be_a(Integer)
      end
    end

    context 'Numeric' do
      let(:type) { Numeric }

      it 'coerces an empty string to nil' do
        expect(subject.call('')).to be_nil
      end

      it 'accepts a non-nil value' do
        expect(subject.call(42)).to be_a(Numeric) # in fact Integer
      end
    end

    context 'Time' do
      let(:type) { Time }

      it 'coerces an empty string to nil' do
        expect(subject.call('')).to be_nil
      end
    end

    context 'String' do
      let(:type) { String }

      it 'coerces to String' do
        expect(subject.call(10)).to eq('10')
      end

      it 'does not coerce an empty string to nil' do
        expect(subject.call('')).to eq('')
      end
    end

    context 'Symbol' do
      let(:type) { Symbol }

      it 'coerces an empty string to nil' do
        expect(subject.call('')).to be_nil
      end
    end

    context 'a type unknown in Dry-types' do
      let(:type) { Complex }

      it 'raises error on init' do
        expect(DryTypes::Params.constants).not_to include(type.name.to_sym)
        expect { subject }.to raise_error(/type Complex should support coercion/)
      end
    end

    context 'the strict mode' do
      let(:strict) { true }

      context 'Boolean' do
        let(:type) { Grape::API::Boolean }

        it 'returns an error when the given value is not Boolean' do
          expect(subject.call(1)).to be_instance_of(Grape::Validations::Types::InvalidValue)
        end

        it 'returns a value as it is when the given value is Boolean' do
          expect(subject.call(true)).to be(true)
        end
      end

      context 'BigDecimal' do
        let(:type) { BigDecimal }

        it 'returns an error when the given value is not BigDecimal' do
          expect(subject.call(1)).to be_instance_of(Grape::Validations::Types::InvalidValue)
        end

        it 'returns a value as it is when the given value is BigDecimal' do
          expect(subject.call(BigDecimal('0'))).to eq(BigDecimal('0'))
        end
      end
    end
  end
end
