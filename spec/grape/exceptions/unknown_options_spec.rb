# frozen_string_literal: true

describe Grape::Exceptions::UnknownOptions do
  describe '#message' do
    let(:error) do
      described_class.new(%i[a b])
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'unknown options: '
      )
    end
  end
end
