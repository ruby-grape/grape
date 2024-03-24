# frozen_string_literal: true

RSpec.describe Grape::Util::AcceptHeaderHandler do
  subject(:match_best_quality_media_type!) { instance.match_best_quality_media_type! }

  let(:instance) do
    described_class.new(
      accept_header: accept_header,
      versions: versions,
      **options
    )
  end
  let(:accept_header) { '*/*' }
  let(:versions) { ['v1'] }
  let(:options) { {} }

  shared_examples 'an invalid accept header exception' do |message|
    before do
      allow(Grape::Exceptions::InvalidAcceptHeader).to receive(:new)
        .with(message, { Grape::Http::Headers::X_CASCADE => 'pass' })
        .and_call_original
    end

    it 'raises a Grape::Exceptions::InvalidAcceptHeader' do
      expect { match_best_quality_media_type! }.to raise_error(Grape::Exceptions::InvalidAcceptHeader)
    end
  end

  describe '#match_best_quality_media_type!' do
    context 'when no vendor set' do
      let(:options) do
        {
          vendor: nil
        }
      end

      it { is_expected.to be_nil }
    end

    context 'when strict header check' do
      let(:options) do
        {
          vendor: 'vendor',
          strict: true
        }
      end

      context 'when accept_header blank' do
        let(:accept_header) { nil }

        it_behaves_like 'an invalid accept header exception', 'Accept header must be set.'
      end

      context 'when vendor not found' do
        let(:accept_header) { '*/*' }

        it_behaves_like 'an invalid accept header exception', 'API vendor or version not found.'
      end
    end

    context 'when media_type found' do
      let(:options) do
        {
          vendor: 'vendor'
        }
      end

      let(:accept_header) { 'application/vnd.vendor-v1+json' }

      it 'yields a media type' do
        expect { |b| instance.match_best_quality_media_type!(&b) }.to yield_with_args(Grape::Util::MediaType.new(type: 'application', subtype: 'vnd.vendor-v1+json'))
      end
    end

    context 'when media_type is not found' do
      let(:options) do
        {
          vendor: 'vendor'
        }
      end

      let(:accept_header) { 'application/vnd.another_vendor-v1+json' }

      context 'when allowed_methods present' do
        subject { instance.match_best_quality_media_type!(allowed_methods: allowed_methods) }

        let(:allowed_methods) { ['OPTIONS'] }

        it { is_expected.to match_array(allowed_methods) }
      end

      context 'when vendor not found' do
        it_behaves_like 'an invalid accept header exception', 'API vendor not found.'
      end

      context 'when version not found' do
        let(:versions) { ['v2'] }
        let(:accept_header) { 'application/vnd.vendor-v1+json' }

        before do
          allow(Grape::Exceptions::InvalidVersionHeader).to receive(:new)
            .with('API version not found.', { Grape::Http::Headers::X_CASCADE => 'pass' })
            .and_call_original
        end

        it 'raises a Grape::Exceptions::InvalidAcceptHeader' do
          expect { match_best_quality_media_type! }.to raise_error(Grape::Exceptions::InvalidVersionHeader)
        end
      end
    end
  end
end
