require 'spec_helper'

describe 'Rack expectations' do

  it 'demonstrates the Tempfile bug' do
    input = Tempfile.new 'rubbish'
    begin
      app = Class.new(Grape::API) do
        format :json
        post do
          { params_keys: params.keys }
        end
      end
      input.write({ test: "123" * 10_000 }.to_json)
      input.rewind
      options = {
        input: input,
        method: 'POST',
        'CONTENT_TYPE' => 'application/json'
      }
      env = Rack::MockRequest.env_for("/", options)
      JSON.parse(app.call(env)[2].body.first)['params_keys'].should =~ ['route_info', 'test']
    ensure
      input.unlink
    end
  end
end
