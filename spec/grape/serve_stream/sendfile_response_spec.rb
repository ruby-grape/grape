# frozen_string_literal: true

describe Grape::ServeStream::SendfileResponse do
  subject(:response) { described_class.new(body) }

  context 'when the body responds to #to_path' do
    let(:body) { Grape::ServeStream::FileBody.new('/tmp/a') }

    describe '#respond_to?' do
      it 'is true for :to_path' do
        expect(response.respond_to?(:to_path)).to be true
      end
    end

    describe '#to_path' do
      it "delegates to the body's #to_path" do
        expect(response.to_path).to eq('/tmp/a')
      end
    end
  end

  context 'when the body does not respond to #to_path' do
    let(:body) { 'plain string body' }

    describe '#respond_to?' do
      it 'is false for :to_path' do
        expect(response.respond_to?(:to_path)).to be false
      end

      it 'falls back to the default behavior for other methods' do
        expect(response.respond_to?(:to_s)).to be true
      end
    end
  end
end
