# frozen_string_literal: true

RSpec.describe Grape::Validations::Validators::Base do
  describe '#inherited' do
    # I tried with `Class.new(Grape::Validations::Validators::Base) but `inherited` is not called.
    context "when class's name does not end with _validator" do
      subject(:custom_validator) { described_class.inherited(TestModule::CustomValidatorABC) }

      before { stub_const('TestModule::CustomValidatorABC', Class.new) }

      it 'registers the custom validator with a short name' do
        expect(Grape::Validations).to receive(:register_validator).with('custom_validator_abc', TestModule::CustomValidatorABC)
        custom_validator
      end
    end

    context "when class's name ends with _validator" do
      subject(:custom_validator) { described_class.inherited(TestModule::CustomValidator) }

      before { stub_const('TestModule::CustomValidator', Class.new) }

      it 'registers the custom validator with a short name not ending with validator' do
        expect(Grape::Validations).to receive(:register_validator).with('custom', TestModule::CustomValidator)
        custom_validator
      end
    end
  end
end
