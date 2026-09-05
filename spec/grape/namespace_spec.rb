# frozen_string_literal: true

describe Grape::Namespace do
  subject(:namespace) { described_class.new('foo', requirements: { id: /\d+/ }, desc: 'bar') }

  describe '#==' do
    it 'is equal to another Namespace with the same space, requirements, and options' do
      other = described_class.new('foo', requirements: { id: /\d+/ }, desc: 'bar')
      expect(namespace).to eq(other)
    end

    it 'is not equal to another Namespace with a different space' do
      other = described_class.new('bar', requirements: { id: /\d+/ }, desc: 'bar')
      expect(namespace).not_to eq(other)
    end

    it 'is not equal to a non-Namespace object' do
      expect(namespace).not_to eq('foo')
    end
  end

  describe '#hash' do
    it 'is the same for two Namespaces with the same space, requirements, and options' do
      other = described_class.new('foo', requirements: { id: /\d+/ }, desc: 'bar')
      expect(namespace.hash).to eq(other.hash)
    end

    it 'differs for Namespaces with different spaces' do
      other = described_class.new('bar', requirements: { id: /\d+/ }, desc: 'bar')
      expect(namespace.hash).not_to eq(other.hash)
    end
  end
end
