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

      # requires Rack 1.6.0 to pass
      # can't check explicitly version of Rack because of https://github.com/rack/rack/issues/773
      pending 'Rack 1.6.0 is required' unless ::Rack.const_defined?(:TempfileReaper) || RUBY_PLATFORM == 'java'

      expect(JSON.parse(app.call(env)[2].body.first)['params_keys']).to match_array('test')
    ensure
      input.close
      input.unlink
    end
  end
end
