require 'spec_helper'

describe Grape::Middleware::Versioner::Header do
  let(:app) { lambda { |env| [200, env, env] } }
  subject { Grape::Middleware::Versioner::Header.new(app, @options || {}) }

  before do
    @options = {
      version_options: {
        using: :header,
        vendor: 'vendor'
      }
    }
  end

  context 'api.type and api.subtype' do
    it 'sets type and subtype to first choice of content type if no preference given' do
      status, _, env = subject.call('HTTP_ACCEPT' => '*/*')
      expect(env['api.type']).to eql 'application'
      expect(env['api.subtype']).to eql 'vnd.vendor+xml'
      expect(status).to eq(200)
    end

    it 'sets preferred type' do
      status, _, env = subject.call('HTTP_ACCEPT' => 'application/*')
      expect(env['api.type']).to eql 'application'
      expect(env['api.subtype']).to eql 'vnd.vendor+xml'
      expect(status).to eq(200)
    end

    it 'sets preferred type and subtype' do
      status, _, env = subject.call('HTTP_ACCEPT' => 'text/plain')
      expect(env['api.type']).to eql 'text'
      expect(env['api.subtype']).to eql 'plain'
      expect(status).to eq(200)
    end
  end

  context 'api.format' do
    it 'is set' do
      status, _, env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor+json')
      expect(env['api.format']).to eql 'json'
      expect(status).to eq(200)
    end

    it 'is nil if not provided' do
      status, _, env = subject.call('HTTP_ACCEPT' => 'application/vnd.vendor')
      expect(env['api.format']).to eql nil
      expect(status).to eq(200)
    end

    ['v1', :v1].each do |version|
      context 'when version is set to #{version{ ' do
        before do
          @options[:versions] = [version]
        end

        it 'is set' do
          status, _, env =  subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1+json')
          expect(env['api.format']).to eql 'json'
          expect(status).to eq(200)
        end

        it 'is nil if not provided' do
          status, _, env =  subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1')
          expect(env['api.format']).to eql nil
          expect(status).to eq(200)
        end
      end
    end
  end

  context 'api.vendor' do
    it 'is set' do
      status, _, env =  subject.call('HTTP_ACCEPT' => 'application/vnd.vendor')
      expect(env['api.vendor']).to eql 'vendor'
      expect(status).to eq(200)
    end

    it 'is set if format provided' do
      status, _, env =  subject.call('HTTP_ACCEPT' => 'application/vnd.vendor+json')
      expect(env['api.vendor']).to eql 'vendor'
      expect(status).to eq(200)
    end

    it 'fails with 406 Not Acceptable if vendor is invalid' do
      expect {
        subject.call('HTTP_ACCEPT' => 'application/vnd.othervendor+json').last
      }.to throw_symbol(
        :error,
        status: 406,
        headers: { 'X-Cascade' => 'pass' },
        message: 'API vendor or version not found.'
      )
    end

    context 'when version is set' do
      before do
        @options[:versions] = ['v1']
      end

      it 'is set' do
        status, _, env =  subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1')
        expect(env['api.vendor']).to eql 'vendor'
        expect(status).to eq(200)
      end

      it 'is set if format provided' do
        status, _, env =  subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1+json')
        expect(env['api.vendor']).to eql 'vendor'
        expect(status).to eq(200)
      end

      it 'fails with 406 Not Acceptable if vendor is invalid' do
        expect {
          subject.call('HTTP_ACCEPT' => 'application/vnd.othervendor-v1+json').last
        }.to throw_symbol(
          :error,
          status: 406,
          headers: { 'X-Cascade' => 'pass' },
          message: 'API vendor or version not found.'
        )
      end
    end
  end

  context 'api.version' do
    before do
      @options[:versions] = ['v1']
    end

    it 'is set' do
      status, _, env =  subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1')
      expect(env['api.version']).to eql 'v1'
      expect(status).to eq(200)
    end

    it 'is set if format provided' do
      status, _, env =  subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1+json')
      expect(env['api.version']).to eql 'v1'
      expect(status).to eq(200)
    end

    it 'fails with 406 Not Acceptable if version is invalid' do
      expect {
        subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v2+json').last
      }.to throw_symbol(
        :error,
        status: 406,
        headers: { 'X-Cascade' => 'pass' },
        message: 'API vendor or version not found.'
      )
    end
  end

  it 'succeeds if :strict is not set' do
    expect(subject.call('HTTP_ACCEPT' => '').first).to eq(200)
    expect(subject.call({}).first).to eq(200)
  end

  it 'succeeds if :strict is set to false' do
    @options[:version_options][:strict] = false
    expect(subject.call('HTTP_ACCEPT' => '').first).to eq(200)
    expect(subject.call({}).first).to eq(200)
  end

  context 'when :strict is set' do
    before do
      @options[:versions] = ['v1']
      @options[:version_options][:strict] = true
    end

    it 'fails with 406 Not Acceptable if header is not set' do
      expect {
        subject.call({}).last
      }.to throw_symbol(
        :error,
        status: 406,
        headers: { 'X-Cascade' => 'pass' },
        message: 'Accept header must be set.'
      )
    end

    it 'fails with 406 Not Acceptable if header is empty' do
      expect {
        subject.call('HTTP_ACCEPT' => '').last
      }.to throw_symbol(
        :error,
        status: 406,
        headers: { 'X-Cascade' => 'pass' },
        message: 'Accept header must be set.'
      )
    end

    it 'fails with 406 Not Acceptable if type is a range' do
      expect {
        subject.call('HTTP_ACCEPT' => '*/*').last
      }.to throw_symbol(
        :error,
        status: 406,
        headers: { 'X-Cascade' => 'pass' },
        message: 'Accept header must not contain ranges ("*").'
      )
    end

    it 'fails with 406 Not Acceptable if subtype is a range' do
      expect {
        subject.call('HTTP_ACCEPT' => 'application/*').last
      }.to throw_symbol(
        :error,
        status: 406,
        headers: { 'X-Cascade' => 'pass' },
        message: 'Accept header must not contain ranges ("*").'
      )
    end

    it 'succeeds if proper header is set' do
      expect(subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1+json').first).to eq(200)
    end
  end

  context 'when :strict and :cascade=>false are set' do
    before do
      @options[:versions] = ['v1']
      @options[:version_options][:strict] = true
      @options[:version_options][:cascade] = false
    end

    it 'fails with 406 Not Acceptable if header is not set' do
      expect {
        subject.call({}).last
      }.to throw_symbol(
        :error,
        status: 406,
        headers: {},
        message: 'Accept header must be set.'
      )
    end

    it 'fails with 406 Not Acceptable if header is empty' do
      expect {
        subject.call('HTTP_ACCEPT' => '').last
      }.to throw_symbol(
        :error,
        status: 406,
        headers: {},
        message: 'Accept header must be set.'
      )
    end

    it 'fails with 406 Not Acceptable if type is a range' do
      expect {
        subject.call('HTTP_ACCEPT' => '*/*').last
      }.to throw_symbol(
        :error,
        status: 406,
        headers: {},
        message: 'Accept header must not contain ranges ("*").'
      )
    end

    it 'fails with 406 Not Acceptable if subtype is a range' do
      expect {
        subject.call('HTTP_ACCEPT' => 'application/*').last
      }.to throw_symbol(
        :error,
        status: 406,
        headers: {},
        message: 'Accept header must not contain ranges ("*").'
      )
    end

    it 'succeeds if proper header is set' do
      expect(subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1+json').first).to eq(200)
    end
  end

  context 'when multiple versions are specified' do
    before do
      @options[:versions] = ['v1', 'v2']
    end

    it 'succeeds with v1' do
      expect(subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v1+json').first).to eq(200)
    end

    it 'succeeds with v2' do
      expect(subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v2+json').first).to eq(200)
    end

    it 'fails with another version' do
      expect {
        subject.call('HTTP_ACCEPT' => 'application/vnd.vendor-v3+json')
      }.to throw_symbol(
        :error,
        status: 406,
        headers: { 'X-Cascade' => 'pass' },
        message: 'API vendor or version not found.'
      )
    end
  end
end
