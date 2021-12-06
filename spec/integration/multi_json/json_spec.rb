# frozen_string_literal: true

require 'spec_helper'

describe Grape::Json do
  it 'uses multi_json' do
    expect(described_class).to eq(::MultiJson)
  end
end
