# frozen_string_literal: true

describe 'GrapeSwagger', if: defined?(GrapeSwagger) do
  # grape-swagger 2.1.4 still calls `desc 'text', options_hash` with a
  # positional Hash. Grape now deprecates that form, and the test suite
  # raises on deprecations, so the documentation class has to be built
  # with the deprecator silenced. The integration value is in asserting
  # that the generated OpenAPI document is still correct.
  let(:app) do
    Grape.deprecator.silence do
      Class.new(Grape::API) do
        format :json

        desc 'Get all widgets', success: { code: 200, message: 'widgets found' }
        params do
          optional :q, type: String, desc: 'search term'
        end
        get '/widgets' do
          [{ id: 1, name: 'gear' }]
        end

        desc 'Create a widget'
        params do
          requires :name, type: String, desc: 'widget name'
        end
        post '/widgets' do
          { id: 2, name: params[:name] }
        end

        add_swagger_documentation info: { title: 'Widget API', version: '1.0' }
      end
    end
  end

  describe 'GET /swagger_doc' do
    let(:swagger) do
      get '/swagger_doc'
      JSON.parse(last_response.body)
    end

    it 'returns a successful Swagger 2.0 document' do
      expect(swagger).to include('swagger' => '2.0')
      expect(last_response).to be_successful
      expect(last_response.content_type).to eq('application/json')
    end

    it 'documents both routes from the mounted API' do
      expect(swagger['paths'].keys).to contain_exactly('/widgets')
      expect(swagger['paths']['/widgets'].keys).to contain_exactly('get', 'post')
    end

    it 'carries the descriptions set via Grape::DSL::Desc' do
      expect(swagger['paths']['/widgets']['get']['description']).to eq('Get all widgets')
      expect(swagger['paths']['/widgets']['post']['description']).to eq('Create a widget')
    end

    it 'translates the success: option into a documented response' do
      expect(swagger['paths']['/widgets']['get']['responses']).to include('200')
    end

    it 'documents the declared query parameter' do
      param = swagger['paths']['/widgets']['get']['parameters'].first
      expect(param).to include('name' => 'q', 'in' => 'query', 'type' => 'string', 'required' => false)
    end
  end

  describe 'GET /swagger_doc/:name' do
    let(:swagger) do
      get '/swagger_doc/widgets'
      JSON.parse(last_response.body)
    end

    it 'returns the documentation scoped to a single resource' do
      expect(swagger['paths']).to have_key('/widgets')
      expect(last_response).to be_successful
      expect(swagger.dig('definitions', 'postWidgets', 'required')).to eq(['name'])
    end
  end

  describe 'add_swagger_documentation' do
    it 'relies on the deprecated positional Hash form of `desc`' do
      expect do
        Class.new(Grape::API) { add_swagger_documentation }
      end.to raise_error(ActiveSupport::DeprecationException, /positional options Hash to `desc`/)
    end
  end
end
