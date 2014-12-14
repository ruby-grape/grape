# encoding: utf-8
require 'spec_helper'

describe Grape::Exceptions::UnknownOptions do
  describe '#message' do
    let(:error) do
      described_class.new([:a, :b])
    end

    it 'contains the problem in the message' do
      expect(error.message).to include(
        'unknown options: '
      )
    end
  end
end
