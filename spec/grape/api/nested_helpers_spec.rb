# frozen_string_literal: true

describe Grape::API::Helpers do
  let(:helper_methods) do
    Module.new do
      extend Grape::API::Helpers

      def current_user
        @current_user ||= params[:current_user]
      end
    end
  end
  let(:nested) do
    context = self

    Class.new(Grape::API) do
      resource :level1 do
        helpers context.helper_methods

        get do
          current_user
        end

        resource :level2 do
          get do
            current_user
          end
        end
      end
    end
  end
  let(:main) do
    context = self

    Class.new(Grape::API) do
      mount context.nested
    end
  end

  def app
    main
  end

  it 'can access helpers from a mounted resource' do
    get '/level1', current_user: 'hello'
    expect(last_response.body).to eq('hello')
  end

  it 'can access helpers from a mounted resource in a nested resource' do
    get '/level1/level2', current_user: 'world'
    expect(last_response.body).to eq('world')
  end
end
