require 'spec_helper'

module Grape
  describe Config do
    let(:config_double) { Module.new { extend Config::SettingStore } }

    context 'when a test_setting exists' do
      let(:default_value) { rand }

      before do
        config_double.setting :test_setting, default: -> { default_value }
      end

      subject(:setting) { config_double[:test_setting] }

      context 'when only the default value is set' do
        it { is_expected.to eq default_value }
      end

      context 'when the value is set' do
        let(:set_value) { -1 }
        before { config_double[:test_setting] = set_value }
        it { is_expected.to eq set_value }
      end

      context 'when the default is true and the value is false' do
        before do
          config_double.setting :boolean_test_setting, default: -> { true }
          config_double[:boolean_test_setting] = false
        end

        subject(:boolean_test_setting) { config_double[:boolean_test_setting] }
        it { is_expected.to be false }
      end
    end
  end
end
