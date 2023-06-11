# frozen_string_literal: true

RSpec.describe Grape::Validations::Validators::Base do
  describe '#inherited' do
    context 'when validator is anonymous' do
      subject(:custom_validator) { Class.new(described_class) }

      it 'does not register the validator' do
        expect(Grape::Validations).not_to receive(:register_validator)
        custom_validator
      end
    end

    # Anonymous class does not have a name and class A < B would leak.
    # Simulates inherited callback
    context "when validator's underscored name does not end with _validator" do
      subject(:custom_validator) { described_class.inherited(TestModule::CustomValidatorABC) }

      before { stub_const('TestModule::CustomValidatorABC', Class.new) }

      it 'registers the custom validator with a short name' do
        expect(Grape::Validations).to receive(:register_validator).with('custom_validator_abc', TestModule::CustomValidatorABC)
        custom_validator
      end
    end

    context "when validator's underscored name ends with _validator" do
      subject(:custom_validator) { described_class.inherited(TestModule::CustomValidator) }

      before { stub_const('TestModule::CustomValidator', Class.new) }

      it 'registers the custom validator with short name not ending with validator' do
        expect(Grape::Validations).to receive(:register_validator).with('custom', TestModule::CustomValidator)
        custom_validator
      end
    end
  end
end
