# frozen_string_literal: true

describe Grape::API::Helpers do
  let(:user) { 'Miguel Caneo' }
  let(:id)   { '42' }
  let(:api_super_class) do
    Class.new(Grape::API) do
      helpers do
        params(:superclass_params) { requires :id, type: String }

        def current_user
          params[:user]
        end
      end
    end
  end
  let(:api_overridden_sub_class) do
    Class.new(api_super_class) do
      params { use :superclass_params }

      helpers do
        def current_user
          "#{params[:user]} with id"
        end
      end

      get 'resource' do
        "#{current_user}: #{params['id']}"
      end
    end
  end
  let(:api_sub_class) do
    Class.new(api_super_class) do
      params { use :superclass_params }

      get 'resource' do
        "#{current_user}: #{params['id']}"
      end
    end
  end
  let(:api_example) do
    Class.new(api_sub_class) do
      params { use :superclass_params }

      get 'resource' do
        "#{current_user}: #{params['id']}"
      end
    end
  end

  context 'non overriding subclass' do
    subject { api_sub_class }

    def app
      subject
    end

    context 'given expected params' do
      it 'inherits helpers from a superclass' do
        get '/resource', id: id, user: user
        expect(last_response.body).to eq("#{user}: #{id}")
      end
    end

    context 'with lack of expected params' do
      it 'returns missing error' do
        get '/resource'
        expect(last_response.body).to eq('id is missing')
      end
    end
  end

  context 'overriding subclass' do
    def app
      api_overridden_sub_class
    end

    context 'given expected params' do
      it 'overrides helpers from a superclass' do
        get '/resource', id: id, user: user
        expect(last_response.body).to eq("#{user} with id: #{id}")
      end
    end

    context 'with lack of expected params' do
      it 'returns missing error' do
        get '/resource'
        expect(last_response.body).to eq('id is missing')
      end
    end
  end

  context 'example subclass' do
    def app
      api_example
    end

    context 'given expected params' do
      it 'inherits helpers from a superclass' do
        get '/resource', id: id, user: user
        expect(last_response.body).to eq("#{user}: #{id}")
      end
    end

    context 'with lack of expected params' do
      it 'returns missing error' do
        get '/resource'
        expect(last_response.body).to eq('id is missing')
      end
    end
  end
end
