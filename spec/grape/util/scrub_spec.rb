# frozen_string_literal: true

describe Grape::Util::Scrub do
  let(:invalid) { (+"a\xFFb").force_encoding(Encoding::UTF_8) }

  describe '.scrub' do
    subject { described_class.scrub(value) }

    context 'with a String holding an invalid byte' do
      let(:value) { invalid }

      it { is_expected.to eq("a\uFFFDb") }
      it { is_expected.to be_valid_encoding }
    end

    context 'with a valid String' do
      let(:value) { +'abc' }

      it { is_expected.to be(value) }
    end

    context 'with a value that is not a String' do
      let(:value) { 42 }

      it { is_expected.to be(value) }
    end
  end

  describe '.blank?' do
    subject { described_class.blank?(value) }

    context 'with a String holding an invalid byte' do
      let(:value) { invalid }

      it { is_expected.to be(false) }
    end

    context 'with a String of whitespace' do
      let(:value) { " \t" }

      it { is_expected.to be(true) }
    end

    context 'with a String that is not blank' do
      let(:value) { 'abc' }

      it { is_expected.to be(false) }
    end

    context 'with nil' do
      let(:value) { nil }

      it { is_expected.to be(true) }
    end

    context 'with an empty Array' do
      let(:value) { [] }

      it { is_expected.to be(true) }
    end

    context 'with false' do
      let(:value) { false }

      it { is_expected.to be(true) }
    end
  end
end
