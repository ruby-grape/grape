# frozen_string_literal: true

describe Grape::API::Helpers do
  let(:app) do
    Class.new(Grape::API) do
      helpers Module.new do
        extend Grape::API::Helpers

        params :drink do
          optional :beer
          optional :wine
          exactly_one_of :beer, :wine
        end
      end
      format :json

      params do
        requires :orderType, type: String, values: %w[food drink]
        given orderType: ->(val) { val == 'food' } do
          optional :pasta
          optional :pizza
          exactly_one_of :pasta, :pizza
        end
        given orderType: ->(val) { val == 'drink' } do
          use :drink
        end
      end
      get do
        declared(params, include_missing: true)
      end
    end
  end

  it 'defines parameters' do
    get '/', orderType: 'food', pizza: 'mista'
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ orderType: 'food',
                                       pasta: nil, pizza: 'mista',
                                       beer: nil, wine: nil }.to_json)
  end
end
