require 'spec_helper'

describe Grape::Validations::RegexpValidator do
  module ValidationsSpec
    module RegexpValidatorSpec
      class API < Grape::API
        default_format :json

        resources :custom_message do
          params do
            requires :name, regexp: { value: /^[a-z]+$/, message: 'format is invalid' }
          end
          get do
          end
        end

        params do
          requires :name, regexp: /^[a-z]+$/
        end
        get do
        end
      end
    end
  end

  def app
    ValidationsSpec::RegexpValidatorSpec::API
  end

  context 'custom validation message' do
    context 'with invalid input' do
      it 'refuses inapppopriate' do
        get '/custom_message', name: 'invalid name'
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('{"error":"name format is invalid"}')
      end

      it 'refuses empty' do
        get '/custom_message', name: ''
        expect(last_response.status).to eq(400)
        expect(last_response.body).to eq('{"error":"name format is invalid"}')
      end
    end

    it 'accepts nil' do
      get '/custom_message', name: nil
      expect(last_response.status).to eq(200)
    end

    it 'accepts valid input' do
      get '/custom_message', name: 'bob'
      expect(last_response.status).to eq(200)
    end
  end

  context 'invalid input' do
    it 'refuses inapppopriate' do
      get '/', name: 'invalid name'
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"name is invalid"}')
    end

    it 'refuses empty' do
      get '/', name: ''
      expect(last_response.status).to eq(400)
      expect(last_response.body).to eq('{"error":"name is invalid"}')
    end
  end

  it 'accepts nil' do
    get '/', name: nil
    expect(last_response.status).to eq(200)
  end

  it 'accepts valid input' do
    get '/', name: 'bob'
    expect(last_response.status).to eq(200)
  end
end
