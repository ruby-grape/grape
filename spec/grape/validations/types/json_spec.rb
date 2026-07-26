# frozen_string_literal: true

RSpec.describe Grape::Validations::Types::Json do
  describe '.parse' do
    it 'returns nil for nil' do
      expect(described_class.parse(nil)).to be_nil
    end

    it 'returns nil for a blank string' do
      expect(described_class.parse('   ')).to be_nil
    end

    it 'parses a JSON object' do
      expect(described_class.parse('{"a":1}')).to eq(a: 1)
    end

    it 'parses JSON containing a blank line' do
      expect(described_class.parse("{\"a\": 1,\n\n\"b\": 2}")).to eq(a: 1, b: 2)
    end

    it 'parses JSON followed by a trailing blank line' do
      expect(described_class.parse("[{\"a\":1}]\n\n")).to eq([{ a: 1 }])
    end
  end

  describe Grape::Validations::Types::JsonArray do
    describe '.parse' do
      it 'returns nil for a blank string' do
        expect(described_class.parse('   ')).to be_nil
      end

      it 'wraps an object containing a blank line in an array' do
        expect(described_class.parse("{\"a\": 1,\n\n\"b\": 2}")).to eq([{ a: 1, b: 2 }])
      end
    end
  end
end
