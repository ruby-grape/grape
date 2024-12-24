# frozen_string_literal: true

describe Grape::Validations::Validators::ContractScopeValidator do
  describe '.inherits' do
    subject { described_class }

    it { is_expected.to be < Grape::Validations::Validators::Base }
  end
end
