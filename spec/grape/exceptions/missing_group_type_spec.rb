# frozen_string_literal: true

RSpec.describe Grape::Exceptions::MissingGroupType do
  describe '#message' do
    subject { described_class.new.message }

    it { is_expected.to include 'group type is required' }
  end

  describe 'deprecated Grape::Exceptions::MissingGroupTypeError' do
    subject { Grape::Exceptions::MissingGroupTypeError.new }

    it 'puts a deprecation warning' do
      expect(Warning).to receive(:warn) do |message|
        expect(message).to include('`Grape::Exceptions::MissingGroupTypeError` is deprecated')
      end

      subject
    end
  end
end
