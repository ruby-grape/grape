require 'spec_helper'
require 'json'
require 'multi_json'

describe Grape::Config do
  describe '.option' do
    it 'defines a configuration option with a default' do
      Grape::Config.option(:foo, default: :bar)

      expect(Grape::Config.foo).to eq :bar
    end

    it 'gets default json processor' do
      expect(Grape::Config.json_processor).to eq JSON
    end

    it 'sets json processor' do
      Grape::Config.json_processor = MultiJson
      expect(Grape::Config.json_processor).to eq MultiJson
      Grape::Config.json_processor = JSON
    end
  end
end
