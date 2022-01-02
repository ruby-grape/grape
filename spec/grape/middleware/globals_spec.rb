# frozen_string_literal: true

describe Grape::Middleware::Globals do
  subject { described_class.new(blank_app) }

  before { allow(subject).to receive(:dup).and_return(subject) }

  let(:blank_app) { ->(_env) { [200, {}, 'Hi there.'] } }

  it 'calls through to the app' do
    expect(subject.call({})).to eq([200, {}, 'Hi there.'])
  end

  context 'environment' do
    it 'sets the grape.request environment' do
      subject.call({})
      expect(subject.env['grape.request']).to be_a(Grape::Request)
    end

    it 'sets the grape.request.headers environment' do
      subject.call({})
      expect(subject.env['grape.request.headers']).to be_a(Hash)
    end

    it 'sets the grape.request.params environment' do
      subject.call('QUERY_STRING' => 'test=1', 'rack.input' => StringIO.new)
      expect(subject.env['grape.request.params']).to be_a(Hash)
    end
  end
end
