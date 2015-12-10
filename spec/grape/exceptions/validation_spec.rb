require 'spec_helper'

describe Grape::Exceptions::Validation do
  it 'fails when params are missing' do
    expect { Grape::Exceptions::Validation.new(message_key: 'presence') }.to raise_error(RuntimeError, 'Params are missing:')
  end

  it 'store message_key' do
    expect(Grape::Exceptions::Validation.new(params: ['id'], message_key: 'presence').message_key).to eq('presence')
  end
end
