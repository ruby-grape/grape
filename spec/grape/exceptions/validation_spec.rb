# frozen_string_literal: true

describe Grape::Exceptions::Validation do
  it 'fails when params are missing' do
    expect { described_class.new(message: 'presence') }.to raise_error(ArgumentError, /missing keyword:.+?params/)
  end

  context 'when message is a Symbol' do
    subject(:error) { described_class.new(params: ['id'], message: :presence) }

    it 'stores message_key' do
      expect(error.message_key).to eq(:presence)
    end

    it 'translates the message' do
      expect(error.message).to eq('is missing')
    end
  end

  context 'when message is a Hash' do
    subject(:error) { described_class.new(params: ['id'], message: { key: :between, min: 2, max: 10 }) }

    before do
      I18n.backend.store_translations(:en, grape: { errors: { messages: { between: 'must be between %<min>s and %<max>s' } } })
    end

    after { I18n.reload! }

    it 'stores the :key entry as message_key' do
      expect(error.message_key).to eq(:between)
    end

    it 'translates the message with interpolation params' do
      expect(error.message).to eq('must be between 2 and 10')
    end
  end

  context 'when message is a Proc' do
    it 'calls the proc to produce the message' do
      expect(described_class.new(params: ['id'], message: -> { 'computed' }).message).to eq('computed')
    end
  end

  context 'when message is a String' do
    subject(:error) { described_class.new(params: ['id'], message: 'raw message') }

    it 'does not store the message_key' do
      expect(error.message_key).to be_nil
    end

    it 'returns the string as-is' do
      expect(error.message).to eq('raw message')
    end
  end
end
