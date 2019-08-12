require 'spec_helper'

describe Grape::API::Instance do
  describe 'boolean constant' do
    module InstanceSpec
      class API < Grape::API
        params do
          requires :message, type: Boolean
        end
        post :echo do
          params[:message]
        end
      end
    end

    def app
      InstanceSpec::API
    end

    it 'sets Boolean as a Virtus::Attribute::Boolean' do
      post '/echo?message=true'
      expect(last_response.status).to eq(201)
    end
  end
end
