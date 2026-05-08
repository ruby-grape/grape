# frozen_string_literal: true

describe Grape::Validations::Types::CustomTypeCoercer do
  describe '#call' do
    context 'when the type is a collection of hashes' do
      subject(:coercer) { described_class.new(type, coerce_method) }

      let(:coerce_method) { ->(val) { JSON.parse(val) } }

      context 'with an Array type' do
        let(:type) { Array }

        it 'symbolizes keys of nested hashes' do
          expect(coercer.call('[{"foo":"bar"}]')).to eq([{ foo: 'bar' }])
        end
      end

      context 'with a Set type' do
        let(:type) { Set }
        let(:coerce_method) { ->(val) { Set.new(JSON.parse(val)) } }

        it 'symbolizes keys of nested hashes' do
          expect(coercer.call('[{"foo":"bar"}]')).to eq(Set[{ foo: 'bar' }])
        end
      end
    end
  end
end
