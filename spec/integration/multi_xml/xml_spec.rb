# frozen_string_literal: true

describe Grape::Xml do
  it 'uses multi_xml' do
    expect(described_class).to eq(::MultiXml)
  end
end
