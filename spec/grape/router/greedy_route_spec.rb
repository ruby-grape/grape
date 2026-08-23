# frozen_string_literal: true

RSpec.describe Grape::Router::GreedyRoute do
  let(:instance) { described_class.new(pattern, endpoint:, allow_header:) }
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

  # A greedy route answers auto-OPTIONS and 405, and Router#process_route asks
  # every route it dispatches for the params of the matched path. A greedy
  # route captures nothing, so there are none.
  describe '#params_for' do
    subject { instance.params_for('/anything') }

    it { is_expected.to be_nil }
  end
end
