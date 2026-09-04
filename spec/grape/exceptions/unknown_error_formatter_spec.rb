# frozen_string_literal: true

describe Grape::Exceptions::UnknownErrorFormatter do
  describe '#message' do
    let(:error) do
      described_class.new('jsonn')
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'unknown error formatter: jsonn'
      )
    end
  end
end
