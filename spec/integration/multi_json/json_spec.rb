# frozen_string_literal: true

describe Grape::Json, if: defined?(::MultiJson) do
  it 'uses multi_json' do
    expect(described_class).to eq(::MultiJson)
  end
end
