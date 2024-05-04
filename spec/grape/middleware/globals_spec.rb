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
      expect(subject.env[Grape::Env::GRAPE_REQUEST]).to be_a(Grape::Request)
    end

    it 'sets the grape.request.headers environment' do
      subject.call({})
      expect(subject.env[Grape::Env::GRAPE_REQUEST_HEADERS]).to be_a(Hash)
    end

    it 'sets the grape.request.params environment' do
      subject.call(Rack::QUERY_STRING => 'test=1', Rack::RACK_INPUT => StringIO.new)
      expect(subject.env[Grape::Env::GRAPE_REQUEST_PARAMS]).to be_a(Hash)
    end
  end
end
