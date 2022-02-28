# frozen_string_literal: true

RSpec.describe Grape::Exceptions::UnsupportedGroupType do
  subject { described_class.new }

  describe '#message' do
    subject { described_class.new.message }

    it { is_expected.to include 'group type must be Array, Hash, JSON or Array[JSON]' }
  end

  describe 'deprecated Grape::Exceptions::UnsupportedGroupTypeError' do
    subject { Grape::Exceptions::UnsupportedGroupTypeError.new }

    it 'puts a deprecation warning' do
      expect(Warning).to receive(:warn) do |message|
        expect(message).to include('`Grape::Exceptions::UnsupportedGroupTypeError` is deprecated')
      end

      subject
    end
  end
end
