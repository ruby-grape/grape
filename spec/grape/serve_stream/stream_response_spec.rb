# frozen_string_literal: true

describe Grape::ServeStream::StreamResponse do
  let(:stream) { StringIO.new('a stream') }

  describe '#hash' do
    it 'matches for two responses wrapping the same stream' do
      one = described_class.new(stream)
      another = described_class.new(stream)
      expect(one.hash).to eq another.hash
    end

    it 'dedups equal responses in a Set' do
      expect(Set.new([described_class.new(stream), described_class.new(stream)]).size).to eq 1
    end
  end
end
