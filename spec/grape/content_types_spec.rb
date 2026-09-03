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

      it { is_expected.to be_frozen }

      it 'returns the same table for an equal registry' do
        expect(subject).to be(described_class.mime_types_for({ xml: 'application/xml;charset=utf-8' }))
      end
    end
  end

  describe '.lookup_for' do
    subject { described_class.lookup_for(from_settings) }

    let(:from_settings) { { json: 'application/json' } }

    it 'holds every format under both spellings' do
      expect(subject).to eq(json: 'application/json', 'json' => 'application/json')
    end

    it { is_expected.to be_frozen }

    context 'with String keys' do
      let(:from_settings) { { 'json' => 'application/json' } }

      it 'answers to either spelling' do
        expect(subject).to eq('json' => 'application/json', json: 'application/json')
      end
    end

    context 'when another registry has the same content types' do
      it 'returns the same table' do
        expect(subject).to be(described_class.lookup_for({ json: 'application/json' }))
      end
    end

    context 'when the registry is mutated after being looked up' do
      it 'keeps answering the original registry' do
        subject
        from_settings[:xml] = 'application/xml'
        expect(described_class.lookup_for({ json: 'application/json' })).to eq(json: 'application/json', 'json' => 'application/json')
      end
    end
  end

  describe '.media_type' do
    subject { described_class.media_type(content_type) }

    context 'with a bare media type' do
      let(:content_type) { 'text/html' }

      it { is_expected.to eq('text/html') }
    end

    context 'with parameters' do
      let(:content_type) { 'text/html; charset=utf-8' }

      it { is_expected.to eq('text/html') }
    end

    context 'with surrounding whitespace before the parameter separator' do
      let(:content_type) { 'text/html ; charset=utf-8' }

      it { is_expected.to eq('text/html') }
    end

    context 'when nil' do
      let(:content_type) { nil }

      it { is_expected.to be_nil }
    end
  end
end
