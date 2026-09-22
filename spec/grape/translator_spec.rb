# frozen_string_literal: true

describe Grape::Translator do
  subject { Class.new(Grape::API) }

  let(:app) { subject }

  before do
    subject.format :json
    subject.params { requires :name, type: String, length: { min: 3 } }
    subject.get('/hello') { { hello: params[:name] } }
  end

  describe 'Grape.translator' do
    it 'resolves through I18n out of the box' do
      expect(Grape.translator).to eq(Grape::Translator::I18n)
    end
  end

  describe 'an error response' do
    let(:i18n_body) do
      get '/hello', name: 'ab'
      last_response.body
    end

    around do |example|
      default = Grape.translator
      example.run
    ensure
      Grape.translator = default
    end

    it 'reads the same with either translator' do
      expected = i18n_body
      Grape.translator = Grape::Translator::Catalog.build

      get '/hello', name: 'ab'
      expect(last_response.body).to eq(expected)
      expect(last_response.status).to eq(400)
    end

    it 'carries an application\'s own override of a Grape message' do
      # Storing before the backend has read its load path is undone by it.
      I18n.backend.__send__(:init_translations) unless I18n.backend.initialized?
      I18n.backend.store_translations(:en, grape: { errors: { messages: { length_min: 'is too short, %<min>s at least' } } })
      Grape.translator = Grape::Translator::Catalog.build

      get '/hello', name: 'ab'
      expect(last_response.body).to include('is too short, 3 at least')
    ensure
      I18n.backend.reload!
    end
  end
end
