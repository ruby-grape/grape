# frozen_string_literal: true

describe Grape::API::Helpers do
  subject do
    shared_params = Module.new do
      extend Grape::API::Helpers

      params :pagination do
        optional :page, type: Integer
        optional :size, type: Integer
      end
    end

    nested = Class.new(Grape::API) do
      params do
        use :pagination
      end
      get '/child' do
        declared(params, include_missing: true)
      end
    end

    Class.new(Grape::API) do
      helpers shared_params
      format :json

      params do
        use :pagination
      end
      get do
        declared(params, include_missing: true)
      end

      mount nested
    end
  end

  def app
    subject
  end

  it 'defines parameters' do
    get '/'
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ page: nil, size: nil }.to_json)
  end

  it 'inherits parameters' do
    get '/child'
    expect(last_response.status).to eq 200
    expect(last_response.body).to eq({ page: nil, size: nil }.to_json)
  end

  describe 'named params used by a mounted API' do
    let(:child) do
      Class.new(Grape::API) do
        params do
          use :page
        end
        get '/child' do
          declared(params)
        end
      end
    end

    let(:page_helpers) do
      proc do
        helpers do
          params :page do
            optional :page, type: Integer
          end
        end
      end
    end

    context 'when the API it is mounted in defines them' do
      subject do
        mounted = child
        page = page_helpers
        Class.new(Grape::API) do
          format :json
          instance_exec(&page)
          mount mounted
        end
      end

      it 'validates them' do
        get '/child', page: 'x'
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq({ error: 'page is invalid' }.to_json)
      end

      it 'declares them' do
        get '/child', page: '2'
        expect(last_response.status).to eq 200
        expect(last_response.body).to eq({ page: 2 }.to_json)
      end
    end

    context 'when an API mounting the one that mounts it defines them' do
      subject do
        mounted = child
        page = page_helpers
        middle = Class.new(Grape::API) { mount mounted }
        Class.new(Grape::API) do
          format :json
          instance_exec(&page)
          mount middle
        end
      end

      it 'validates them' do
        get '/child', page: 'x'
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq({ error: 'page is invalid' }.to_json)
      end
    end

    context 'when its superclass defines them as well' do
      subject do
        superclass = Class.new(Grape::API) do
          helpers do
            params :page do
              optional :page, type: Integer
            end
          end
        end
        mounted = Class.new(superclass) do
          params do
            use :page
          end
          get '/child' do
            declared(params)
          end
        end
        Class.new(Grape::API) do
          format :json
          helpers do
            params :page do
              optional :page, type: String
            end
          end
          mount mounted
        end
      end

      it "uses its superclass's" do
        get '/child', page: 'x'
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq({ error: 'page is invalid' }.to_json)
      end
    end

    context 'when it is mounted under a typed route_param' do
      subject do
        mounted = child
        page = page_helpers
        Class.new(Grape::API) do
          format :json
          instance_exec(&page)
          namespace :users do
            route_param :id, type: Integer do
              mount mounted
            end
          end
        end
      end

      it 'answers an invalid route param with 400' do
        get '/users/abc/child'
        expect(last_response.status).to eq 400
        expect(last_response.body).to eq({ error: 'id is invalid' }.to_json)
      end
    end

    context 'when only a sibling namespace defines them' do
      subject do
        mounted = child
        page = page_helpers
        Class.new(Grape::API) do
          namespace :a do
            instance_exec(&page)
          end
          namespace :b do
            mount mounted
          end
        end
      end

      it 'raises when the API compiles' do
        expect { subject.compile! }.to raise_error(RuntimeError, 'Params :page not found!')
      end
    end

    context 'when it is served without being mounted' do
      it 'raises when it compiles, not when it is defined' do
        expect { child }.not_to raise_error
        expect { child.compile! }.to raise_error(RuntimeError, 'Params :page not found!')
      end
    end
  end
end
