require 'spec_helper'

describe Grape::Validations::NonEmptyValidator do
  module ValidationsSpec
    module NonEmptyValidatorSpec
      class API < Grape::API
        default_format :json

        params do
          requires :name, non_empty: true
        end
        get do

        end

        params do
          requires :name, non_empty: false
        end
        get '/allow_empty' do

        end
      end
    end
  end

  def app
    ValidationsSpec::NonEmptyValidatorSpec::API
  end

  context 'invalid input' do
    it 'refuses empty string' do
      get '/', name: ""
      expect(last_response.status).to eq(400)
    end

    it 'refuses only whitespaces' do
      get '/', name: "   "
      expect(last_response.status).to eq(400)

      get '/', name: "  \n "
      expect(last_response.status).to eq(400)

      get '/', name: "\n"
      expect(last_response.status).to eq(400)
    end

    it 'refuses nil' do
      get '/', name: nil
      expect(last_response.status).to eq(400)
    end
  end

  it 'accepts valid input' do
    get '/', name: "bob"
    expect(last_response.status).to eq(200)
  end

  it 'accepts empty input when non_empty is false' do
    get '/allow_empty', name: ""
    expect(last_response.status).to eq(200)
  end

end
