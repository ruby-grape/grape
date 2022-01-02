# frozen_string_literal: true

describe Grape::Exceptions::InvalidResponse do
  describe '#message' do
    let(:error) { described_class.new }

    it 'contains the problem in the message' do
      expect(error.message).to include('Invalid response')
    end
  end
end
