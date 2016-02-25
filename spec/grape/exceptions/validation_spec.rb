require 'spec_helper'

describe Grape::Exceptions::Validation do
  it 'fails when params are missing' do
    expect { Grape::Exceptions::Validation.new(message: 'presence') }.to raise_error(RuntimeError, 'Params are missing:')
  end
end
