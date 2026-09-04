# frozen_string_literal: true

describe Grape::Parser::Base do
  describe '.call' do
    it 'raises NotImplementedError' do
      expect { described_class.call({}, {}) }.to raise_error(NotImplementedError)
    end
  end
end
