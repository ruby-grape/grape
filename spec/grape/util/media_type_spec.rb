# frozen_string_literal: true

require 'grape/util/media_type'

RSpec.describe Grape::Util::MediaType do
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
      let(:header) { 'text/html' }

      it 'returns an instance of MediaType' do
        expect(media_type).to be_a described_class
        expect(media_type.type).to eq('text')
        expect(media_type.subtype).to eq('html')
      end

      context 'when header is a vendor mime type' do
        let(:header) { 'application/vnd.test-v1+json' }

        it 'returns an instance of MediaType' do
          expect(media_type).to be_a described_class
          expect(media_type.type).to eq('application')
          expect(media_type.subtype).to eq('vnd.test-v1+json')
          expect(media_type.vendor).to eq('test')
          expect(media_type.version).to eq('v1')
          expect(media_type.format).to eq('json')
        end

        context 'when header is a vendor mime type without version' do
          let(:header) { 'application/vnd.ms-word' }

          it 'returns an instance of MediaType' do
            expect(media_type).to be_a described_class
            expect(media_type.type).to eq('application')
            expect(media_type.subtype).to eq('vnd.ms-word')
            expect(media_type.vendor).to eq('ms')
            expect(media_type.version).to eq('word')
            expect(media_type.format).to be_nil
          end
        end
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

      context 'when header is a vendor mime type' do
        let(:media_type) { 'application/vnd.test-v1+json' }

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.best_quality' do
    subject { described_class.best_quality(header, available_media_types) }

    let(:available_media_types) { %w[application/json text/html] }

    context 'when header is blank?' do
      let(:header) { nil }

      it 'return a MediaType with the first available_media_types' do
        expect(media_type).to be_a described_class
        expect(media_type.type).to eq('application')
        expect(media_type.subtype).to eq('json')
        expect(media_type.vendor).to be_nil
        expect(media_type.version).to be_nil
        expect(media_type.format).to be_nil
      end
    end

    context 'when header is not blank' do
      let(:header) { 'text/html' }

      it 'calls Rack::Utils.best_q_match' do
        expect(Rack::Utils).to receive(:best_q_match).and_call_original
        expect(media_type).to be_a described_class
        expect(media_type.type).to eq('text')
        expect(media_type.subtype).to eq('html')
        expect(media_type.vendor).to be_nil
        expect(media_type.version).to be_nil
        expect(media_type.format).to be_nil
      end
    end
  end
end
