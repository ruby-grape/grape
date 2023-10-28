# frozen_string_literal: true

describe Grape::Util::Xml, if: defined?(::MultiXml) do
  it 'uses multi_xml' do
    expect(described_class).to eq(::MultiXml)
  end
end
