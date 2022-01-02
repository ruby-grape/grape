# frozen_string_literal: true

describe '.configure' do
  before do
    Grape.configure do |config|
      config.param_builder = 42
    end
  end

  after do
    Grape.config.reset
  end

  it 'is configured to the new value' do
    expect(Grape.config.param_builder).to eq 42
  end
end
