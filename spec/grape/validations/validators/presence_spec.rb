require 'spec_helper'

describe Grape::Validations::PresenceValidator do

  module ValidationsSpec
    module PresenceValidatorSpec
      class API < Grape::API
        default_format :json

        resource :bacons do
          get do
            "All the bacon"
          end
        end

        params do
          requires :id, regexp: /^[0-9]+$/
        end
        post do
          { ret: params[:id] }
        end

        params do
          requires :name, :company
        end
        get do
          "Hello"
        end

        params do
          requires :user, type: Hash do
            requires :first_name
            requires :last_name
          end
        end
        get '/nested' do
          "Nested"
        end

        params do
          requires :admin, type: Hash do
            requires :admin_name
            requires :super, type: Hash do
              requires :user, type: Hash do
                requires :first_name
                requires :last_name
              end
            end
          end
        end
        get '/nested_triple' do
          "Nested triple"
        end
      end
    end
  end

  def app
    ValidationsSpec::PresenceValidatorSpec::API
  end

  it 'does not validate for any params' do
    get "/bacons"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("All the bacon".to_json)
  end

  it 'validates id' do
    post '/'
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"id is missing"}')

    io = StringIO.new('{"id" : "a56b"}')
    post '/', {}, 'rack.input' => io, 'CONTENT_TYPE' => 'application/json', 'CONTENT_LENGTH' => io.length
    expect(last_response.body).to eq('{"error":"id is invalid"}')
    expect(last_response.status).to eq(400)

    io = StringIO.new('{"id" : 56}')
    post '/', {}, 'rack.input' => io, 'CONTENT_TYPE' => 'application/json', 'CONTENT_LENGTH' => io.length
    expect(last_response.body).to eq('{"ret":56}')
    expect(last_response.status).to eq(201)
  end

  it 'validates name, company' do
    get '/'
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"name is missing"}')

    get '/', name: "Bob"
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"company is missing"}')

    get '/', name: "Bob", company: "TestCorp"
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("Hello".to_json)
  end

  it 'validates nested parameters' do
    get '/nested'
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"user is missing, user[first_name] is missing, user[last_name] is missing"}')

    get '/nested', user: { first_name: "Billy" }
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"user[last_name] is missing"}')

    get '/nested', user: { first_name: "Billy", last_name: "Bob" }
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("Nested".to_json)
  end

  it 'validates triple nested parameters' do
    get '/nested_triple'
    expect(last_response.status).to eq(400)
    expect(last_response.body).to include '{"error":"admin is missing'

    get '/nested_triple', user: { first_name: "Billy" }
    expect(last_response.status).to eq(400)
    expect(last_response.body).to include '{"error":"admin is missing'

    get '/nested_triple', admin: { super: { first_name: "Billy" } }
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"admin[admin_name] is missing, admin[super][user] is missing, admin[super][user][first_name] is missing, admin[super][user][last_name] is missing"}')

    get '/nested_triple', super: { user: { first_name: "Billy", last_name: "Bob" } }
    expect(last_response.status).to eq(400)
    expect(last_response.body).to include '{"error":"admin is missing'

    get '/nested_triple', admin: { super: { user: { first_name: "Billy" } } }
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"admin[admin_name] is missing, admin[super][user][last_name] is missing"}')

    get '/nested_triple', admin: { admin_name: 'admin', super: { user: { first_name: "Billy" } } }
    expect(last_response.status).to eq(400)
    expect(last_response.body).to eq('{"error":"admin[super][user][last_name] is missing"}')

    get '/nested_triple', admin: { admin_name: 'admin', super: { user: { first_name: "Billy", last_name: "Bob" } } }
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq("Nested triple".to_json)
  end

end
