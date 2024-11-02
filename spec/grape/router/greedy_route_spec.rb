# frozen_string_literal: true

RSpec.describe Grape::Router::GreedyRoute do
  let(:instance) { described_class.new(pattern, options) }
  let(:index) { 0 }
  let(:pattern) { :pattern }
  let(:params) do
    { a_param: 1 }.freeze
  end
  let(:options) do
    { params: params }.freeze
  end

  describe '#pattern' do
    subject { instance.pattern }

    it { is_expected.to eq(pattern) }
  end

  describe '#options' do
    subject { instance.options }

    it { is_expected.to eq(options) }
  end

  describe '#params' do
    subject { instance.params }

    it { is_expected.to eq(params) }
  end

  describe '#attributes' do
    subject { instance.attributes }

    it { is_expected.to eq(options) }
  end
end
