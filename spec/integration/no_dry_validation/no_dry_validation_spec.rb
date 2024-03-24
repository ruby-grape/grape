# frozen_string_literal: true

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', '..', 'lib'))
require 'grape'

describe Grape do
  let(:app) do
    Class.new(Grape::API) do
      resource :foos do
        params do
          requires :type, type: String
          optional :limit, type: Integer
        end
        get do
          declared(params).to_json
        end
      end
    end
  end

  it 'executes request normally' do
    get '/foos', type: 'bar', limit: 4, qux: 'tee'

    expect(last_response.status).to eq(200)
    result = JSON.parse(last_response.body)
    expect(result).to eq({ 'type' => 'bar', 'limit' => 4 })
  end
end
