require 'spec_helper'

describe Grape::Json do
  it 'uses multi_json' do
    expect(Grape::Json).to eq(::MultiJson)
  end
end
