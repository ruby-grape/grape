# frozen_string_literal: true

describe Grape::Exceptions::InvalidVersionerOption do
  describe '#message' do
    let(:error) do
      described_class.new('headers')
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'unknown :using for versioner: headers'
      )
    end
  end
end
