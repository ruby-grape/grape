require 'spec_helper'

describe Grape::ParameterTypes do
  class FooType
    def self.parse(_)
    end
  end

  class BarType
    def self.parse
    end
  end

  describe '::primitive?' do
    [
      Integer, Float, Numeric, BigDecimal,
      Virtus::Attribute::Boolean, String, Symbol,
      Date, DateTime, Time, Rack::Multipart::UploadedFile
    ].each do |type|
      it "recognizes #{type} as a primitive" do
        expect(described_class.primitive?(type)).to be_truthy
      end
    end

    it 'identifies unknown types' do
      expect(described_class.primitive?(Object)).to be_falsy
      expect(described_class.primitive?(FooType)).to be_falsy
    end
  end

  describe '::structure?' do
    [
      Hash, Array, Set
    ].each do |type|
      it "recognizes #{type} as a structure" do
        expect(described_class.structure?(type)).to be_truthy
      end
    end
  end

  describe '::custom_type?' do
    it 'returns false if the type does not respond to :parse' do
      expect(described_class.custom_type?(Object)).to be_falsy
    end

    it 'returns true if the type responds to :parse with one argument' do
      expect(described_class.custom_type?(FooType)).to be_truthy
    end

    it 'returns false if the type\'s #parse method takes other than one argument' do
      expect(described_class.custom_type?(BarType)).to be_falsy
    end
  end
end
