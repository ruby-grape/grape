# frozen_string_literal: true

describe Grape::ContentTypes do
  describe 'DEFAULTS' do
    subject { described_class::DEFAULTS }

    let(:expected_value) do
      {
        xml: 'application/xml',
        serializable_hash: 'application/json',
        json: 'application/json',
        binary: 'application/octet-stream',
        txt: 'text/plain'
      }.freeze
    end

    it { is_expected.to eq(expected_value) }
  end

  describe 'MIME_TYPES' do
    subject { described_class::MIME_TYPES }

    let(:expected_value) do
      {
        'application/xml' => :xml,
        'application/json' => :json,
        'application/octet-stream' => :binary,
        'text/plain' => :txt
      }.freeze
    end

    it { is_expected.to eq(expected_value) }
  end

  describe '.content_types_for' do
    subject { described_class.content_types_for(from_settings) }

    context 'when from_settings is present' do
      let(:from_settings) { { a: :b } }

      it { is_expected.to eq(from_settings) }
    end

    context 'when from_settings is not present' do
      let(:from_settings) { nil }

      it { is_expected.to be(described_class::DEFAULTS) }
    end
  end

  describe '.mime_types_for' do
    subject { described_class.mime_types_for(from_settings) }

    context 'when from_settings is equal to Grape::ContentTypes::DEFAULTS' do
      let(:from_settings) do
        {
          xml: 'application/xml',
          serializable_hash: 'application/json',
          json: 'application/json',
          binary: 'application/octet-stream',
          txt: 'text/plain'
        }.freeze
      end

      it { is_expected.to be(described_class::MIME_TYPES) }
    end

    context 'when from_settings is not equal to Grape::ContentTypes::DEFAULTS' do
      let(:from_settings) do
        {
          xml: 'application/xml;charset=utf-8'
        }
      end

      it { is_expected.to eq('application/xml' => :xml) }
    end
  end
end
