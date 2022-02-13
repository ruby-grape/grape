# frozen_string_literal: true

RSpec.describe Grape::Exceptions::MissingGroupType do
  describe '#message' do
    subject { described_class.new.message }

    it { is_expected.to include 'group type is required' }
  end

  describe '#alias' do
    subject { described_class }

    it { is_expected.to eq(Grape::Exceptions::MissingGroupTypeError) }
  end
end
