# frozen_string_literal: true

RSpec.describe Grape do
  describe '.config' do
    subject { described_class.config }

    it { is_expected.to eq(param_builder: Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder) }
  end
end
