# frozen_string_literal: true

describe Grape do
  describe '.deprecator' do
    subject { described_class.deprecator }

    it { is_expected.to be_an(ActiveSupport::Deprecation) }

    it 'is memoized' do
      expect(subject).to be(described_class.deprecator)
    end

    it 'announces Grape as the gem being deprecated from' do
      expect(subject.gem_name).to eq('Grape')
    end

    # The horizon is the version a deprecation says it will be removed in, so it
    # has to be ahead of the one running. It was hardcoded for three major
    # versions and announced a removal version that had already shipped.
    it 'announces the next major version as the removal horizon' do
      expect(subject.deprecation_horizon).to eq("#{Gem::Version.new(Grape::VERSION).segments.first + 1}.0")
    end

    it 'announces a horizon later than the running version' do
      expect(Gem::Version.new(subject.deprecation_horizon)).to be > Gem::Version.new(Grape::VERSION)
    end
  end
end
