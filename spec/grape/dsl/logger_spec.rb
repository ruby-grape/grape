# frozen_string_literal: true

describe Grape::DSL::Logger do
  let(:dummy_logger) do
    Class.new do
      extend Grape::DSL::Logger
      def self.global_setting(key, value = nil)
        if value
          global_setting_hash[key] = value
        else
          global_setting_hash[key]
        end
      end

      def self.global_setting_hash
        @global_setting_hash ||= {}
      end
    end
  end

  describe '.logger' do
    context 'when setting a logger' do
      subject { dummy_logger.logger :my_logger }

      it { is_expected.to eq(:my_logger) }
    end

    context 'when retrieving logger' do
      context 'when never been set' do
        subject { dummy_logger.logger }

        before { allow(Logger).to receive(:new).with($stdout).and_return(:stdout_logger) }

        it { is_expected.to eq(:stdout_logger) }
      end

      context 'when already set' do
        subject { dummy_logger.logger }

        before { dummy_logger.logger :my_logger }

        it { is_expected.to eq(:my_logger) }
      end
    end
  end
end
