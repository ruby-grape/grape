# frozen_string_literal: true

RSpec.describe Grape::Exceptions::UnsupportedGroupType do
  subject { described_class.new }

  describe '#message' do
    subject { described_class.new.message }

    it { is_expected.to include 'group type must be Array, Hash, JSON or Array[JSON]' }
  end

  describe 'deprecated Grape::Exceptions::UnsupportedGroupTypeError' do
    subject { Grape::Exceptions::UnsupportedGroupTypeError.new }

    around do |example|
      old_deprec_behavior = ActiveSupport::Deprecation.behavior
      ActiveSupport::Deprecation.behavior = :raise
      example.run
      ActiveSupport::Deprecation.behavior = old_deprec_behavior
    end

    it 'puts a deprecation warning' do
      expect { subject }.to raise_error(ActiveSupport::DeprecationException)
    end
  end
end
