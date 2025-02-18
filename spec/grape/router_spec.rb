# frozen_string_literal: true

describe Grape::Router do
  describe '.normalize_path' do
    subject { described_class.normalize_path(path) }

    context 'when no leading slash' do
      let(:path) { 'foo%20bar%20baz' }

      it { is_expected.to eq '/foo%20bar%20baz' }
    end

    context 'when path ends with slash' do
      let(:path) { '/foo%20bar%20baz/' }

      it { is_expected.to eq '/foo%20bar%20baz' }
    end

    context 'when path has recurring slashes' do
      let(:path) { '////foo%20bar%20baz' }

      it { is_expected.to eq '/foo%20bar%20baz' }
    end

    context 'when not greedy' do
      let(:path) { '/foo%20bar%20baz' }

      it { is_expected.to eq '/foo%20bar%20baz' }
    end

    context 'when encoded string in lowercase' do
      let(:path) { '/foo%aabar%aabaz' }

      it { is_expected.to eq '/foo%AAbar%AAbaz' }
    end

    context 'when nil' do
      let(:path) { nil }

      it { is_expected.to eq '/' }
    end

    context 'when empty string' do
      let(:path) { '' }

      it { is_expected.to eq '/' }
    end

    context 'when encoding is different' do
      subject { described_class.normalize_path(path).encoding }

      let(:path) { '/foo%AAbar%AAbaz'.b }

      it { is_expected.to eq(Encoding::BINARY) }
    end
  end
end
