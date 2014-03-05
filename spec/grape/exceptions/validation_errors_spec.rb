require 'spec_helper'
require 'ostruct'

describe Grape::Exceptions::ValidationErrors do
  let(:validation_message) { "FooBar is invalid" }
  let(:validation_error) { OpenStruct.new(param: validation_message) }

  context "message" do
    context "is not repeated" do
      let(:error) do
        described_class.new(errors: [validation_error, validation_error])
      end
      subject(:message) { error.message.split(',').map(&:strip) }

      it { expect(message).to include validation_message }
      it { expect(message.size).to eq 1 }
    end
  end
end
