# frozen_string_literal: true

RSpec.describe Grape::Router::GreedyRoute do
  let(:instance) { described_class.new(pattern, endpoint: endpoint, allow_header: allow_header) }
  let(:pattern) { :pattern }
  let(:endpoint) { instance_double(Grape::Endpoint) }
  let(:allow_header) { false }

  describe 'inheritance' do
    subject { instance }

    it { is_expected.to be_a(Grape::Router::BaseRoute) }
  end

  describe '#pattern' do
    subject { instance.pattern }

    it { is_expected.to eq(pattern) }
  end

  describe '#endpoint' do
    subject { instance.endpoint }

    it { is_expected.to eq(endpoint) }
  end

  describe '#allow_header' do
    subject { instance.allow_header }

    it { is_expected.to eq(allow_header) }
  end

  describe '#params' do
    subject { instance.params }

    it { is_expected.to be_nil }
  end
end
