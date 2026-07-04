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
      format: nil,
      version: nil,
      requirements: {}
    )
  end

  describe 'inheritance' do
    subject { described_class.new(endpoint, :get, pattern, options, forward_match: false) }

    it { is_expected.to be_a(Grape::Router::BaseRoute) }
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
