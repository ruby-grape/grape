# frozen_string_literal: true

describe Grape::ServeStream::FileBody do
  describe '#to_path' do
    it 'returns the path' do
      expect(described_class.new('/tmp/a').to_path).to eq('/tmp/a')
    end
  end

  describe '#each' do
    it 'yields the file contents in chunks' do
      Tempfile.create('grape-file-body-spec') do |file|
        file.write('hello world')
        file.flush

        chunks = []
        # rubocop:disable Style/MapIntoArray -- FileBody#each is not Enumerable, so #map is unavailable here.
        described_class.new(file.path).each { |chunk| chunks << chunk }
        # rubocop:enable Style/MapIntoArray
        expect(chunks.join).to eq('hello world')
      end
    end
  end

  describe '#==' do
    it 'is true for two bodies with an equal path' do
      expect(described_class.new('/tmp/a')).to eq(described_class.new(+'/tmp/a'))
    end

    it 'is false for two bodies with a different path' do
      expect(described_class.new('/tmp/a')).not_to eq(described_class.new('/tmp/b'))
    end
  end

  describe '#hash' do
    it 'matches for two bodies with an equal path' do
      expect(described_class.new('/tmp/a').hash).to eq described_class.new(+'/tmp/a').hash
    end

    it 'dedups equal bodies in a Set' do
      expect(Set.new([described_class.new('/tmp/a'), described_class.new(+'/tmp/a')]).size).to eq 1
    end
  end
end
