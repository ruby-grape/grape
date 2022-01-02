# frozen_string_literal: true

describe Rack::Sendfile do
  subject do
    content_object = file_object
    app = Class.new(Grape::API) do
      use Rack::Sendfile
      format :json
      get do
        if content_object.is_a?(String)
          sendfile content_object
        else
          stream content_object
        end
      end
    end

    options = {
      method: 'GET',
      'HTTP_X_SENDFILE_TYPE' => 'X-Accel-Redirect',
      'HTTP_X_ACCEL_MAPPING' => '/accel/mapping/=/replaced/'
    }
    env = Rack::MockRequest.env_for('/', options)
    app.call(env)
  end

  context 'when calling sendfile' do
    let(:file_object) do
      '/accel/mapping/some/path'
    end

    it 'contains Sendfile headers' do
      headers = subject[1]
      expect(headers).to include('X-Accel-Redirect')
    end
  end

  context 'when streaming non file content' do
    let(:file_object) do
      double(:file_object, each: nil)
    end

    it 'not contains Sendfile headers' do
      headers = subject[1]
      expect(headers).not_to include('X-Accel-Redirect')
    end
  end
end
