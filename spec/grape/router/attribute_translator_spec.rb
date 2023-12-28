# frozen_string_literal: true

describe Grape::Router::AttributeTranslator do
  described_class::ROUTE_ATTRIBUTES.each do |attribute|
    describe "##{attribute}" do
      it "returns value from #{attribute} key if present" do
        translator = described_class.new(attribute => 'value')
        expect(translator.public_send(attribute)).to eq('value')
      end

      it "returns nil from #{attribute} key if missing" do
        translator = described_class.new
        expect(translator.public_send(attribute)).to be_nil
      end
    end

    describe "##{attribute}=" do
      it "sets value for #{attribute}", :aggregate_failures do
        translator = described_class.new(attribute => 'value')
        expect do
          translator.public_send("#{attribute}=", 'new_value')
        end.to change(translator, attribute).from('value').to('new_value')
      end
    end
  end
end
