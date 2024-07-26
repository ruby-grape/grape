# frozen_string_literal: true

describe Grape::Middleware::Versioner do
  subject { described_class.using(strategy) }

  context 'when :path' do
    let(:strategy) { :path }

    it { is_expected.to eq(Grape::Middleware::Versioner::Path) }
  end

  context 'when :header' do
    let(:strategy) { :header }

    it { is_expected.to eq(Grape::Middleware::Versioner::Header) }
  end

  context 'when :param' do
    let(:strategy) { :param }

    it { is_expected.to eq(Grape::Middleware::Versioner::Param) }
  end

  context 'when :accept_version_header' do
    let(:strategy) { :accept_version_header }

    it { is_expected.to eq(Grape::Middleware::Versioner::AcceptVersionHeader) }
  end

  context 'when unknown' do
    let(:strategy) { :unknown }

    it 'raises an error' do
      expect { subject }.to raise_error Grape::Exceptions::InvalidVersionerOption, Grape::Exceptions::InvalidVersionerOption.new(strategy).message
    end
  end
end
