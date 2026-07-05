# frozen_string_literal: true

RSpec.describe Grape::Router::Route do
  let(:instance) { described_class.new(endpoint, :get, pattern, options, forward_match:) }
  let(:endpoint) { instance_double(Grape::Endpoint) }
  let(:options) { {} }
  let(:pattern) do
    Grape::Router::Pattern.new(
      origin: '/mounty',
      suffix: '',
      anchor: true,
      params: {},
      version: nil,
      requirements: {}
    )
  end

  describe 'inheritance' do
    subject { described_class.new(endpoint, :get, pattern, options, forward_match: false) }

    it { is_expected.to be_a(Grape::Router::BaseRoute) }
  end

  describe 'route attributes' do
    subject(:route) do
      described_class.new(endpoint, :get, pattern, options, forward_match: false,
                                                            version: 'v1', namespace: '/things', prefix: '/api',
                                                            requirements: { id: /\d+/ }, anchor: false, settings: { a: 1 })
    end

    it 'exposes them as readers' do
      expect(route.version).to eq('v1')
      expect(route.namespace).to eq('/things')
      expect(route.prefix).to eq('/api')
      expect(route.requirements).to eq(id: /\d+/)
      expect(route.anchor).to be(false)
      expect(route.settings).to eq(a: 1)
    end

    it 'does not leak them into the options Hash' do
      %i[version namespace prefix requirements anchor settings].each do |key|
        expect(route.options).not_to have_key(key)
      end
    end

    context 'when omitted' do
      subject(:route) { described_class.new(endpoint, :get, pattern, options, forward_match: false) }

      it 'defaults to nil' do
        expect(route.version).to be_nil
        expect(route.namespace).to be_nil
        expect(route.prefix).to be_nil
        expect(route.requirements).to be_nil
        expect(route.anchor).to be_nil
        expect(route.settings).to be_nil
      end
    end
  end

  describe '#match?' do
    subject { instance.match?(input) }

    context 'when forward_match is true' do
      let(:forward_match) { true }

      context 'with the exact origin' do
        let(:input) { '/mounty' }

        it { is_expected.to be_truthy }
      end

      context 'with a subpath under the origin' do
        let(:input) { '/mounty/awesome/deep' }

        it 'matches on the origin prefix' do
          expect(subject).to be_truthy
        end
      end

      context 'with a path outside the origin' do
        let(:input) { '/other' }

        it { is_expected.to be_falsey }
      end

      context 'with a blank input' do
        let(:input) { '' }

        it { is_expected.to be(false) }
      end
    end

    context 'when forward_match is false' do
      let(:forward_match) { false }

      context 'with the exact origin' do
        let(:input) { '/mounty' }

        it { is_expected.to be_truthy }
      end

      context 'with a subpath under the origin' do
        let(:input) { '/mounty/awesome/deep' }

        it 'does not match beyond the anchored pattern' do
          expect(subject).to be_falsey
        end
      end

      context 'with a blank input' do
        let(:input) { '' }

        it { is_expected.to be(false) }
      end
    end
  end
end
