require 'spec_helper'

describe Grape::Middleware::Versioner::Param do
  let(:app) { ->(env) { [200, env, env['api.version']] } }
  subject { Grape::Middleware::Versioner::Param.new(app, @options || {}) }

  it 'sets the API version based on the default param (apiver)' do
    env = Rack::MockRequest.env_for('/awesome', params: { 'apiver' => 'v1' })
    expect(subject.call(env)[1]['api.version']).to eq('v1')
  end

  it 'cuts (only) the version out of the params' do
    env = Rack::MockRequest.env_for('/awesome', params: { 'apiver' => 'v1', 'other_param' => '5' })
    env['rack.request.query_hash'] = Rack::Utils.parse_nested_query(env['QUERY_STRING'])
    expect(subject.call(env)[1]['rack.request.query_hash']['apiver']).to be_nil
    expect(subject.call(env)[1]['rack.request.query_hash']['other_param']).to eq('5')
  end

  it 'provides a nil version if no version is given' do
    env = Rack::MockRequest.env_for('/')
    expect(subject.call(env).last).to be_nil
  end

  context 'with specified parameter name' do
    before { @options = { parameter: 'v' } }
    it 'sets the API version based on the custom parameter name' do
      env = Rack::MockRequest.env_for('/awesome', params: { 'v' => 'v1' })
      expect(subject.call(env)[1]['api.version']).to eq('v1')
    end
    it 'does not set the API version based on the default param' do
      env = Rack::MockRequest.env_for('/awesome', params: { 'apiver' => 'v1' })
      expect(subject.call(env)[1]['api.version']).to be_nil
    end
  end

  context 'with specified versions' do
    before { @options = { versions: %w(v1 v2) } }
    it 'throws an error if a non-allowed version is specified' do
      env = Rack::MockRequest.env_for('/awesome', params: { 'apiver' => 'v3' })
      expect(catch(:error) { subject.call(env) }[:status]).to eq(404)
    end
    it 'allows versions that have been specified' do
      env = Rack::MockRequest.env_for('/awesome', params: { 'apiver' => 'v1' })
      expect(subject.call(env)[1]['api.version']).to eq('v1')
    end
  end

  it 'returns a 200 when no version is set (matches the first version found)' do
    @options = {
      versions: ['v1'],
      version_options: { using: :header }
    }
    env = Rack::MockRequest.env_for('/awesome', params: {})
    expect(subject.call(env).first).to eq(200)
  end
end
