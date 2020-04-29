# frozen_string_literal: true

require 'spec_helper'

describe Grape::API::Instance do
  describe 'boolean constant' do
    module DefinesBooleanInstanceSpec
      class API < Grape::API
        params do
          requires :message, type: Boolean
        end
        post :echo do
          { class: params[:message].class.name, value: params[:message] }
        end
      end
    end

    def app
      DefinesBooleanInstanceSpec::API
    end

    it 'sets "true" as a Boolean type' do
      post '/echo?message=true'
      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq({ class: 'TrueClass', value: true }.to_s)
    end

    it 'sets "1" as a Boolean true' do
      post '/echo?message=1'
      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq({ class: 'TrueClass', value: true }.to_s)
    end

    it 'sets "false" as a Boolean type' do
      post '/echo?message=false'
      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq({ class: 'FalseClass', value: false }.to_s)
    end

    it 'sets "0" as a Boolean false' do
      post '/echo?message=0'
      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq({ class: 'FalseClass', value: false }.to_s)
    end

    # Pending
    xit 'sets "" as a nil' do
      post '/echo?message='
      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq({ class: 'NilClass', value: nil }.to_s)
    end

    context 'Params endpoint type' do
      subject { DefinesBooleanInstanceSpec::API.new.router.map['POST'].first.options[:params]['message'][:type] }
      it 'params type is a boolean' do
        is_expected.to eq 'Grape::API::Boolean'
      end
    end
  end
end
