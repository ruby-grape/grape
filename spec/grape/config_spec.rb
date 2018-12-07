require 'spec_helper'

module Grape
  describe Config do
    let(:config_double) { Module.new { extend Config::SettingStore } }

    context 'when configured' do
      subject(:configure) do
        config_double.configure do |config|
          config.param_builder = 42
        end
      end

      it 'changes the value' do
        expect { configure }.to change { config_double.param_builder }.to(42)
      end
    end
  end
end
