# frozen_string_literal: true

describe Grape::Exceptions::MissingOption do
  describe '#message' do
    let(:error) do
      described_class.new(:path)
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'you must specify :path options'
      )
    end
  end
end
