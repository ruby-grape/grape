require 'spec_helper'
require 'grape/middleware/globals'

describe Grape::Middleware::Globals do
  let(:app) { lambda { |env| [200, env, 'Howdy Doody'] } }
  subject { Grape::Middleware::Globals.new(app, {}) }

  context 'with params' do
    it 'sets the params based on the params' do
      env = Rack::MockRequest.env_for('/awesome', params: {'swank' => 'bank'})
      expect(subject.call(env)[1]['grape.request.params']).to eq({'swank' => 'bank'})
      expect(subject.call(env)[1]['grape.request.headers']).to eq({})
    end
  end

  context 'with headers' do
    it 'sets the headers based on the headers' do
      env = Rack::MockRequest.env_for('/awesome', params: {})
      env['HTTP_MONKEY'] = 'I_BANANA'

      expect(subject.call(env)[1]['grape.request.params']).to eq({})
      expect(subject.call(env)[1]['grape.request.headers']).to eq({'Monkey' => 'I_BANANA'})
    end
  end

  context 'with headers and params' do
    it 'sets the headers based on the headers' do
      env = Rack::MockRequest.env_for('/awesome', params: {'grapes' => 'wrath'})
      env['HTTP_MONKEY'] = 'I_BANANA'

      expect(subject.call(env)[1]['grape.request.params']).to eq({'grapes' => 'wrath'})
      expect(subject.call(env)[1]['grape.request.headers']).to eq({'Monkey' => 'I_BANANA'})
    end
  end
end
