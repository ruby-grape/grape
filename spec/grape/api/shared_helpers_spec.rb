# frozen_string_literal: true

describe Grape::API::Helpers do
  subject do
    shared_params = Module.new do
      extend Grape::API::Helpers

      params :pagination do
        optional :page, type: Integer
        optional :size, type: Integer
      end
    end

    nested = Class.new(Grape::API) do
      params do
        use :pagination
      end
      get '/child' do
        declared(params, include_missing: true)
      end
    end

    Class.new(Grape::API) do
      helpers shared_params
      format :json

      params do
        use :pagination
      end
      get do
        declared(params, include_missing: true)
      end

      mount nested
    end
  end

  def app
    subject
  end

  it 'defines parameters' do
    get '/'
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ page: nil, size: nil }.to_json)
  end

  it 'inherits parameters' do
    get '/child'
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ page: nil, size: nil }.to_json)
  end
end
