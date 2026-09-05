# frozen_string_literal: true

describe Grape::Formatter::Json do
  describe '.call' do
    it 'returns the string representation of a Grape::PrecompiledJson object' do
      precompiled = Grape::PrecompiledJson.new('{"a":1}')
      expect(described_class.call(precompiled, {})).to eq('{"a":1}')
    end

    it 'calls #to_json when the object responds to it' do
      object = { a: 1 }
      expect(described_class.call(object, {})).to eq(object.to_json)
    end

    it 'falls back to Grape::Json.dump when the object does not respond to #to_json' do
      object = Object.new
      allow(object).to receive(:respond_to?).with(:to_json).and_return(false)
      expect(described_class.call(object, {})).to eq(Grape::Json.dump(object))
    end
  end
end
