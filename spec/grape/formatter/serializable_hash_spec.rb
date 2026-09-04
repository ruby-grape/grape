# frozen_string_literal: true

describe Grape::Formatter::SerializableHash do
  describe '.call' do
    it 'returns the string representation of a Grape::PrecompiledJson object' do
      precompiled = Grape::PrecompiledJson.new('{"a":1}')
      expect(described_class.call(precompiled, {})).to eq('{"a":1}')
    end

    it 'returns a String object unchanged' do
      expect(described_class.call('already a string', {})).to eq('already a string')
    end

    it 'serializes an object responding to #serializable_hash' do
      object = Class.new do
        def serializable_hash
          { a: 1 }
        end
      end.new
      expect(described_class.call(object, {})).to eq(Grape::Json.dump(a: 1))
    end

    it 'serializes an Array of objects responding to #serializable_hash' do
      klass = Class.new do
        def initialize(value)
          @value = value
        end

        def serializable_hash
          { value: @value }
        end
      end
      objects = [klass.new(1), klass.new(2)]
      expect(described_class.call(objects, {})).to eq(Grape::Json.dump([{ value: 1 }, { value: 2 }]))
    end

    it 'serializes a Hash, recursively serializing its values' do
      object = Class.new do
        def serializable_hash
          { a: 1 }
        end
      end.new
      expect(described_class.call({ nested: object }, {})).to eq(Grape::Json.dump(nested: { a: 1 }))
    end

    it 'serializes a Hash, leaving non-serializable leaf values untouched' do
      expect(described_class.call({ plain: 'value' }, {})).to eq(Grape::Json.dump(plain: 'value'))
    end

    it 'calls #to_json when the object responds to it and is not otherwise serializable' do
      object = 1234
      expect(described_class.call(object, {})).to eq(object.to_json)
    end

    it 'falls back to Grape::Json.dump when the object is not serializable and does not respond to #to_json' do
      object = Object.new
      allow(object).to receive(:respond_to?).and_call_original
      allow(object).to receive(:respond_to?).with(:to_json).and_return(false)
      expect(described_class.call(object, {})).to eq(Grape::Json.dump(object))
    end
  end
end
