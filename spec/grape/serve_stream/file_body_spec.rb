# frozen_string_literal: true

describe Grape::ServeStream::FileBody do
  describe '#hash' do
    it 'matches for two bodies with an equal path' do
      expect(described_class.new('/tmp/a').hash).to eq described_class.new(+'/tmp/a').hash
    end

    it 'dedups equal bodies in a Set' do
      expect(Set.new([described_class.new('/tmp/a'), described_class.new(+'/tmp/a')]).size).to eq 1
    end
  end
end
