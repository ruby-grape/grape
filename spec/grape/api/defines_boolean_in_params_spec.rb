# frozen_string_literal: true

describe Grape::API::Instance do
  describe 'boolean constant' do
    let(:app) do
      Class.new(Grape::API) do
        params do
          requires :message, type: Grape::API::Boolean
        end
        post :echo do
          { class: params[:message].class.name, value: params[:message] }
        end
      end
    end

    let(:expected_body) do
      { class: 'TrueClass', value: true }.to_s
    end

    it 'sets Boolean as a type' do
      post '/echo?message=true'
      expect(last_response.status).to eq(201)
      expect(last_response.body).to eq expected_body
    end

    context 'Params endpoint type' do
      subject { app.new.router.map['POST'].first.options[:params]['message'][:type] }

      it 'params type is a boolean' do
        expect(subject).to eq 'Grape::API::Boolean'
      end
    end
  end
end
