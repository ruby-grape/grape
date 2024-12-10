# frozen_string_literal: true

describe Grape::DSL::Headers do
  subject { dummy_class.new }

  let(:dummy_class) do
    Class.new do
      include Grape::DSL::Headers
    end
  end

  let(:header_data) do
    { 'first key' => 'First Value',
      'second key' => 'Second Value' }
  end

  context 'when headers are set' do
    describe '#header' do
      before do
        header_data.each { |k, v| subject.header(k, v) }
      end

      describe 'get' do
        it 'returns a specifc value' do
          expect(subject.header['first key']).to eq 'First Value'
          expect(subject.header['second key']).to eq 'Second Value'
        end

        it 'returns all set headers' do
          expect(subject.header).to eq header_data
          expect(subject.headers).to eq header_data
        end
      end

      describe 'set' do
        it 'returns value' do
          expect(subject.header('third key', 'Third Value'))
          expect(subject.header['third key']).to eq 'Third Value'
        end
      end

      describe 'delete' do
        it 'deletes a header key-value pair' do
          expect(subject.header('first key')).to eq header_data['first key']
          expect(subject.header).not_to have_key('first key')
        end
      end
    end
  end

  context 'when no headers are set' do
    describe '#header' do
      it 'returns nil' do
        expect(subject.header['first key']).to be_nil
        expect(subject.header('first key')).to be_nil
      end
    end
  end

  context 'when non-string headers are set' do
    describe '#header' do
      it 'converts non-string header values to strings' do
        subject.header('integer key', 123)
        expect(subject.header['integer key']).to eq '123'
      end

      it 'emits a warning if the header value is not a string' do
        expect { subject.header('integer key', 123) }.to output("Header value for 'integer key' is not a string. Converting to string.\n").to_stderr
      end
    end
  end
end
