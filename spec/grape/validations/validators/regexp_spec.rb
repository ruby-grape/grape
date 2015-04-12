require 'spec_helper'

describe Grape::Validations::RegexpValidator do
  module ValidationsSpec
    module RegexpValidatorSpec
      class API < Grape::API
        default_format :json

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

  context 'invalid input' do
    it 'refuses inapppopriate' do
      get '/', name: 'invalid name'
      expect(last_response.status).to eq(400)
    end

    it 'refuses empty' do
      get '/', name: ''
      expect(last_response.status).to eq(400)
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
