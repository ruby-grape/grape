require 'spec_helper'

describe Grape::Validations do
  before do
    module CustomValidationsSpec
      class DefaultLength < Grape::Validations::Base
        def validate_param!(attr_name, params)
          @option = params[:max].to_i if params.key?(:max)
          return if params[attr_name].length <= @option
          fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "must be at the most #{@option} characters long"
        end
      end
    end
  end

  subject do
    Class.new(Grape::API) do
      params do
        requires :text, default_length: 140
      end
      get do
        'bacon'
      end
    end
  end

  def app
    subject
  end

  context 'using a custom length validator' do
    it 'under 140 characters' do
      get '/', text: 'abc'
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end
    it 'over 140 characters' do
      get '/', text: 'a' * 141
      expect(last_response.status).to eq 400
      expect(last_response.body).to eq 'text must be at the most 140 characters long'
    end
    it 'specified in the query string' do
      get '/', text: 'a' * 141, max: 141
      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'bacon'
    end
  end
end
