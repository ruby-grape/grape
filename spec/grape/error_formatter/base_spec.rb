# frozen_string_literal: true

describe Grape::ErrorFormatter::Base do
  describe '.format_structured_message' do
    it 'raises NotImplementedError' do
      expect { described_class.format_structured_message({}) }.to raise_error(NotImplementedError)
    end
  end
end
