# frozen_string_literal: true

describe Grape::Util::Lazy::Value do
  subject(:configuration) { Grape::Util::EndpointConfiguration.new(config) }

  describe '#evaluate' do
    context 'when the configuration is empty' do
      let(:config) { {} }

      it 'answers nil for any key' do
        expect(configuration[:missing].evaluate).to be_nil
      end

      it 'answers nil for a nested key' do
        expect(configuration[:db][:host].evaluate).to be_nil
      end
    end

    context 'when the configuration holds the key' do
      let(:config) { { path: 'votes', db: { host: 'localhost' }, hosts: %w[a b] } }

      it 'answers the value' do
        expect(configuration[:path].evaluate).to eq('votes')
      end

      it 'answers a value nested in a Hash' do
        expect(configuration[:db][:host].evaluate).to eq('localhost')
      end

      it 'answers a value nested in an Array' do
        expect(configuration[:hosts][1].evaluate).to eq('b')
      end

      it 'answers nil past a leaf' do
        expect(configuration[:path][:nope].evaluate).to be_nil
      end

      it 'answers the whole configuration with indifferent access' do
        expect(configuration.evaluate).to eq('path' => 'votes', 'db' => { 'host' => 'localhost' }, 'hosts' => %w[a b])
      end

      it 'reads a Symbol key through a String' do
        expect(configuration['path'].evaluate).to eq('votes')
      end
    end

    context 'when the configuration came from YAML or ENV, with String keys' do
      let(:config) { { 'path' => 'votes', 'db' => { 'host' => 'localhost' } } }

      it 'reads a String key through a Symbol' do
        expect(configuration[:path].evaluate).to eq('votes')
      end

      it 'reads a nested String key through a Symbol' do
        expect(configuration[:db][:host].evaluate).to eq('localhost')
      end
    end
  end

  describe '#evaluate_from' do
    let(:config) { {} }

    it 'replays the path against another configuration' do
      read = configuration[:path]
      expect(read.evaluate_from(Grape::Util::EndpointConfiguration.new(path: 'scores'))).to eq('scores')
    end

    it 'replays a nested path against another configuration' do
      read = configuration[:db][:host]
      expect(read.evaluate_from(Grape::Util::EndpointConfiguration.new(db: { host: 'example.com' }))).to eq('example.com')
    end

    it 'answers nil when the other configuration lacks the path' do
      read = configuration[:path]
      expect(read.evaluate_from(Grape::Util::EndpointConfiguration.new(other: 1))).to be_nil
    end
  end

  describe '#[]' do
    let(:config) { { path: 'votes' } }

    it 'leaves the configuration it was read from alone' do
      configuration[:db][:host]
      expect(configuration.evaluate).to eq('path' => 'votes')
    end

    it 'answers a fresh read each time' do
      expect(configuration[:path]).not_to be(configuration[:path])
    end
  end

  describe '#[]=' do
    let(:config) { { db: { host: 'localhost' } } }

    it 'writes a top-level key' do
      configuration[:path] = 'votes'
      expect(configuration[:path].evaluate).to eq('votes')
    end

    it 'writes through a nested read' do
      configuration[:db][:port] = 5432
      expect(configuration[:db][:port].evaluate).to eq(5432)
    end

    it 'leaves the Hash the mount supplied alone' do
      configuration[:path] = 'votes'
      configuration[:db][:port] = 5432
      expect(config).to eq(db: { host: 'localhost' })
    end
  end

  describe '#to_s' do
    let(:config) { { path: 'votes' } }

    it 'answers the string form of the value' do
      expect("/#{configuration[:path]}").to eq('/votes')
    end

    it 'answers an empty string when the path leads nowhere' do
      expect("/#{configuration[:missing]}").to eq('/')
    end
  end
end
