# frozen_string_literal: true

describe Grape::Exceptions::Validation do
  it 'fails when params are missing' do
    expect { described_class.new(message: 'presence') }.to raise_error(ArgumentError, /missing keyword:.+?params/)
  end

  context 'when message is a symbol' do
    it 'stores message_key' do
      expect(described_class.new(params: ['id'], message: :presence).message_key).to eq(:presence)
    end
  end

  context 'when message is a Hash' do
    it 'stores the :key entry as message_key' do
      expect(described_class.new(params: ['size'], message: { key: :length, min: 2, max: 10 }).message_key).to eq(:length)
    end
  end
end
