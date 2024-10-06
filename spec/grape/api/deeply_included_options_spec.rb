# frozen_string_literal: true

describe 'Deep included options' do
  let(:app) do
    main_api = api
    Class.new(Grape::API) do
      mount main_api
    end
  end

  let(:api) do
    deeply_included_options = options
    Class.new(Grape::API) do
      include deeply_included_options

      resource :users do
        get do
          status 200
        end
      end
    end
  end

  let(:options) do
    deep_included_options_default = default
    Module.new do
      extend ActiveSupport::Concern
      include deep_included_options_default
    end
  end

  let(:default) do
    Module.new do
      extend ActiveSupport::Concern
      included do
        format :json
      end
    end
  end

  it 'works for unspecified format' do
    get '/users'
    expect(last_response.status).to be 200
    expect(last_response.content_type).to eql 'application/json'
  end

  it 'works for specified format' do
    get '/users.json'
    expect(last_response.status).to be 200
    expect(last_response.content_type).to eql 'application/json'
  end

  it "doesn't work for format different than specified" do
    get '/users.txt'
    expect(last_response.status).to be 404
  end
end
