# frozen_string_literal: true

describe Grape::DSL::Logger do
  subject { Class.new(dummy_logger) }

  let(:dummy_logger) do
    Class.new do
      extend Grape::DSL::Logger
    end
  end

  let(:logger) { instance_double(::Logger) }

  describe '.logger' do
    it 'sets a logger' do
      subject.logger logger
      expect(subject.logger).to eq logger
    end

    it 'returns a logger' do
      expect(subject.logger(logger)).to eq logger
    end
  end
end
