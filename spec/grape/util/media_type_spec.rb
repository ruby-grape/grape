# frozen_string_literal: true

RSpec.describe Grape::Util::MediaType do
  shared_examples 'MediaType' do
    it { is_expected.to eq(described_class.new(type: type, subtype: subtype)) }
  end

  describe '.parse' do
    subject(:media_type) { described_class.parse(header) }

    context 'when header blank?' do
      let(:header) { nil }

      it { is_expected.to be_nil }
    end

    context 'when header is not a mime type' do
      let(:header) { 'abc' }

      it { is_expected.to be_nil }
    end

    context 'when header is a valid mime type' do
      let(:header) { [type, subtype].join('/') }
      let(:type) { 'text' }
      let(:subtype) { 'html' }

      it_behaves_like 'MediaType'

      context 'when header is a vendor mime type' do
        let(:type) { 'application' }
        let(:subtype) { 'vnd.test-v1+json' }

        it_behaves_like 'MediaType'
      end

      context 'when header is a vendor mime type without version' do
        let(:type) { 'application' }
        let(:subtype) { 'vnd.ms-word' }

        it_behaves_like 'MediaType'
      end
    end
  end

  describe '.match?' do
    subject { described_class.match?(media_type) }

    context 'when media_type is blank?' do
      let(:media_type) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when header is not a mime type' do
      let(:media_type) { 'abc' }

      it { is_expected.to be_falsey }
    end

    context 'when header is a valid mime type but not vendor' do
      let(:media_type) { 'text/html' }

      it { is_expected.to be_falsey }
    end

    context 'when header is a vendor mime type' do
      let(:media_type) { 'application/vnd.test-v1+json' }

      it { is_expected.to be_truthy }
    end
  end

  describe '.best_quality' do
    subject(:media_type) { described_class.best_quality(header, available_media_types) }

    let(:available_media_types) { %w[application/json text/html] }

    context 'when header is blank?' do
      let(:header) { nil }
      let(:type) { 'application' }
      let(:subtype) { 'json' }

      it_behaves_like 'MediaType'
    end

    context 'when header is not blank' do
      let(:header) { [type, subtype].join('/') }
      let(:type) { 'text' }
      let(:subtype) { 'html' }

      it 'calls Rack::Utils.best_q_match' do
        allow(Rack::Utils).to receive(:best_q_match).and_call_original
        expect(media_type).to eq(described_class.new(type: type, subtype: subtype))
      end
    end
  end

  describe '.==' do
    subject { described_class.new(type: type, subtype: subtype) }

    let(:type) { 'application' }
    let(:subtype) { 'vnd.test-v1+json' }
    let(:other_media_type_class) { Class.new(Struct.new(:type, :subtype, :vendor, :version, :format)) }
    let(:other_media_type_instance) { other_media_type_class.new(type, subtype, 'test', 'v1', 'json') }

    it { is_expected.not_to eq(other_media_type_class.new(type, subtype, 'test', 'v1', 'json')) }
  end

  describe '.hash' do
    subject { Set.new([described_class.new(type: type, subtype: subtype)]) }

    let(:type) { 'text' }
    let(:subtype) { 'html' }

    it { is_expected.to include(described_class.new(type: type, subtype: subtype)) }
  end
end
