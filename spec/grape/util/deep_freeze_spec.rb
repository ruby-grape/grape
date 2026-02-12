# frozen_string_literal: true

describe Grape::Util::DeepFreeze do
  describe '.deep_freeze' do
    subject { described_class.deep_freeze(obj) }

    context 'with a String' do
      let(:obj) { +'mutable' }

      it { is_expected.to be_frozen }
    end

    context 'with an Array of strings' do
      let(:obj) { [+'a', +'b'] }

      it 'freezes the array and each element' do
        subject
        expect(obj).to be_frozen
        expect(obj).to all(be_frozen)
      end
    end

    context 'with a nested Array' do
      let(:obj) { [[+'a'], [+'b']] }

      it 'freezes all nested elements' do
        subject
        expect(obj).to all(be_frozen)
        expect(obj).to all(all(be_frozen))
      end
    end

    context 'with a Hash' do
      let(:obj) { { +'key' => +'value' } }

      it 'freezes the hash, its keys and its values' do
        subject
        expect(obj).to be_frozen
        obj.each do |k, v|
          expect(k).to be_frozen
          expect(v).to be_frozen
        end
      end
    end

    context 'with a nested Hash' do
      let(:obj) { { a: { +'nested_key' => +'nested_value' } } }

      it 'freezes nested hashes and their contents' do
        subject
        inner = obj[:a]
        expect(inner).to be_frozen
        inner.each do |k, v|
          expect(k).to be_frozen
          expect(v).to be_frozen
        end
      end
    end

    context 'with a Proc' do
      let(:obj) { proc {} }

      it 'returns it unchanged without freezing' do
        expect(subject).to equal(obj)
        expect(obj).not_to be_frozen
      end
    end

    context 'with an already-frozen object' do
      let(:obj) { 'frozen' }

      it 'returns it without raising' do
        expect { subject }.not_to raise_error
        expect(subject).to equal(obj)
      end
    end

    context 'with nil' do
      let(:obj) { nil }

      it 'returns nil without raising' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
