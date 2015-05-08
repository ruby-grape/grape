require 'spec_helper'

describe Rack do
  it 'correctly populates params from a Tempfile' do
    input = Tempfile.new 'rubbish'
    begin
      app = Class.new(Grape::API) do
        format :json
        post do
          { params_keys: params.keys }
        end
      end
      input.write({ test: '123' * 10_000 }.to_json)
      input.rewind
      options = {
        input: input,
        method: 'POST',
        'CONTENT_TYPE' => 'application/json'
      }
      env = Rack::MockRequest.env_for('/', options)

      unless RUBY_PLATFORM == 'java'
        major, minor, release = Rack.release.split('.').map(&:to_i)
        pending 'Rack 1.5.3 or 1.6.1 required' unless major >= 1 && ((minor == 5 && release >= 3) || (minor >= 6))
      end

      expect(JSON.parse(app.call(env)[2].body.first)['params_keys']).to match_array('test')
    ensure
      input.close
      input.unlink
    end
  end
end
