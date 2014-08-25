require 'spec_helper'

describe Grape::API::Helpers do
  module Grape
    class API
      module HelpersSpec
        module SharedParams
          extend Grape::SharedParams

          params :pagination do
            optional :page, type: Integer
            optional :size, type: Integer
          end
        end
      end
    end
  end

  subject do
    Class.new(Grape::API) do
      format :json

      shared_params 'a name' do
        params :pagination_more do
          optional :per_page, type: Integer
        end
      end

      include_params Grape::API::HelpersSpec::SharedParams, 'a name'
      params do
        use :pagination
        use :pagination_more
      end
      get do
        declared(params, include_missing: true)
      end
    end
  end

  def app
    subject
  end

  it 'defines parameters' do
    get '/'
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ page: nil, size: nil, per_page: nil }.to_json)
  end

  context 'deprecated API' do
    module Grape
      class API
        module HelpersSpec
          module SharedParamsOld
            extend Grape::API::Helpers

            params :pagination do
              optional :page, type: Integer
              optional :size, type: Integer
            end
          end
        end
      end
    end

    subject do
      Class.new(Grape::API) do
        helpers Grape::API::HelpersSpec::SharedParamsOld
        format :json

        params do
          use :pagination
        end
        get do
          declared(params, include_missing: true)
        end
      end
    end

    def app
      subject
    end

    it 'defines parameters' do
      get '/'
      expect(last_response.status).to eq 200
    end
  end
end
