# frozen_string_literal: true

describe Grape::Middleware::Versioner::AcceptVersionHeader do
  subject { described_class.new(app, **@options) }

  let(:app) { ->(env) { [200, env, env] } }

  before do
    @options = {
      version_options: {
        using: :accept_version_header
      }
    }
  end

  describe '#bad encoding' do
    before do
      @options[:versions] = %w[v1]
    end

    it 'does not raise an error' do
      expect do
        subject.call('HTTP_ACCEPT_VERSION' => "\x80")
      end.to throw_symbol(:error, status: 406, headers: { 'X-Cascade' => 'pass' }, message: 'The requested version is not supported.')
    end
  end

  context 'api.version' do
    before do
      @options[:versions] = ['v1']
    end

    it 'is set' do
      status, _, env = subject.call('HTTP_ACCEPT_VERSION' => 'v1')
      expect(env[Grape::Env::API_VERSION]).to eql 'v1'
      expect(status).to eq(200)
    end

    it 'is set if format provided' do
      status, _, env = subject.call('HTTP_ACCEPT_VERSION' => 'v1')
      expect(env[Grape::Env::API_VERSION]).to eql 'v1'
      expect(status).to eq(200)
    end

    it 'fails with 406 Not Acceptable if version is not supported' do
      expect do
        subject.call('HTTP_ACCEPT_VERSION' => 'v2').last
      end.to throw_symbol(
        :error,
        status: 406,
        headers: { 'X-Cascade' => 'pass' },
        message: 'The requested version is not supported.'
      )
    end
  end

  it 'succeeds if :strict is not set' do
    expect(subject.call('HTTP_ACCEPT_VERSION' => '').first).to eq(200)
    expect(subject.call({}).first).to eq(200)
  end

  it 'succeeds if :strict is set to false' do
    @options[:version_options][:strict] = false
    expect(subject.call('HTTP_ACCEPT_VERSION' => '').first).to eq(200)
    expect(subject.call({}).first).to eq(200)
  end

  context 'when :strict is set' do
    before do
      @options[:versions] = ['v1']
      @options[:version_options][:strict] = true
    end

    it 'fails with 406 Not Acceptable if header is not set' do
      expect do
        subject.call({}).last
      end.to throw_symbol(
        :error,
        status: 406,
        headers: { 'X-Cascade' => 'pass' },
        message: 'Accept-Version header must be set.'
      )
    end

    it 'fails with 406 Not Acceptable if header is empty' do
      expect do
        subject.call('HTTP_ACCEPT_VERSION' => '').last
      end.to throw_symbol(
        :error,
        status: 406,
        headers: { 'X-Cascade' => 'pass' },
        message: 'Accept-Version header must be set.'
      )
    end

    it 'succeeds if proper header is set' do
      expect(subject.call('HTTP_ACCEPT_VERSION' => 'v1').first).to eq(200)
    end
  end

  context 'when :strict and cascade: false' do
    before do
      @options[:versions] = ['v1']
      @options[:version_options][:strict] = true
      @options[:version_options][:cascade] = false
    end

    it 'fails with 406 Not Acceptable if header is not set' do
      expect do
        subject.call({}).last
      end.to throw_symbol(
        :error,
        status: 406,
        headers: {},
        message: 'Accept-Version header must be set.'
      )
    end

    it 'fails with 406 Not Acceptable if header is empty' do
      expect do
        subject.call('HTTP_ACCEPT_VERSION' => '').last
      end.to throw_symbol(
        :error,
        status: 406,
        headers: {},
        message: 'Accept-Version header must be set.'
      )
    end

    it 'succeeds if proper header is set' do
      expect(subject.call('HTTP_ACCEPT_VERSION' => 'v1').first).to eq(200)
    end
  end
end
