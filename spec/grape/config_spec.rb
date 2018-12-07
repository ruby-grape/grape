require 'spec_helper'

describe '.configure' do
  let!(:grape_double) { Module.new { extend Grape::Config } }

  context 'when not configured' do
    it 'does not change when resetted' do
      expect { grape_double.config.reset }
        .not_to(change { grape_double.config.param_builder })
    end
  end

  context 'when configured' do
    subject(:configure) do
      grape_double.configure do |config|
        config.param_builder = 42
      end
    end

    it 'changes the value' do
      expect { configure }.to change { grape_double.config.param_builder }.to(42)
    end

    it 'can be restored by resetting' do
      configure
      expect { grape_double.config.reset }
        .to change { grape_double.config.param_builder }
        .from(42)
    end
  end
end
