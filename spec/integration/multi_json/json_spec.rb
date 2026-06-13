# frozen_string_literal: true

# grape_entity depends on multi-json and it breaks the test.
describe Grape::Json, if: (defined?(MultiJSON) || defined?(MultiJson)) && !defined?(Grape::Entity) do
  subject { described_class }

  # Exercise the full request/response JSON stack (parser + formatter) through
  # the active multi_json backend (MultiJSON on >= 1.21, the legacy MultiJson
  # facade on < 1.21); a deprecated call anywhere in the path would raise via
  # the suite's deprecation handler.
  context 'with a Grape API that parses and renders JSON' do
    let(:app) do
      Class.new(Grape::API) do
        format :json

        post '/echo' do
          { received: params[:value] }
        end
      end
    end

    it 'parses the JSON body and renders the JSON response' do
      env = Rack::MockRequest.env_for('/echo', method: Rack::POST, input: JSON.dump(value: 'hi'), 'CONTENT_TYPE' => 'application/json')
      response = Rack::MockResponse[*app.call(env)]

      expect(response.status).to eq(201)
      expect(JSON.parse(response.body)).to eq('received' => 'hi')
    end
  end
end
