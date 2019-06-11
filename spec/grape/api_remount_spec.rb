require 'spec_helper'
require 'shared/versioning_examples'

describe Grape::API do
  subject(:a_remounted_api) { Class.new(Grape::API) }
  let(:root_api) { Class.new(Grape::API) }

  def app
    root_api
  end

  describe 'remounting an API' do
    context 'with a defined route' do
      before do
        a_remounted_api.get '/votes' do
          '10 votes'
        end
      end

      context 'when mounting one instance' do
        before do
          root_api.mount a_remounted_api
        end

        it 'can access the endpoint' do
          get '/votes'
          expect(last_response.body).to eql '10 votes'
        end
      end

      context 'when mounting twice' do
        before do
          root_api.mount a_remounted_api => '/posts'
          root_api.mount a_remounted_api => '/comments'
        end

        it 'can access the votes in both places' do
          get '/posts/votes'
          expect(last_response.body).to eql '10 votes'
          get '/comments/votes'
          expect(last_response.body).to eql '10 votes'
        end
      end

      context 'when mounting on namespace' do
        before do
          stub_const('StaticRefToAPI', a_remounted_api)
          root_api.namespace 'posts' do
            mount StaticRefToAPI
          end

          root_api.namespace 'comments' do
            mount StaticRefToAPI
          end
        end

        it 'can access the votes in both places' do
          get '/posts/votes'
          expect(last_response.body).to eql '10 votes'
          get '/comments/votes'
          expect(last_response.body).to eql '10 votes'
        end
      end
    end

    describe 'with dynamic configuration' do
      context 'when mounting an endpoint conditional on a configuration' do
        subject(:a_remounted_api) do
          Class.new(Grape::API) do
            get 'always' do
              'success'
            end

            given configuration[:mount_sometimes] do
              get 'sometimes' do
                'sometimes'
              end
            end
          end
        end

        it 'mounts the endpoints only when configured to do so' do
          root_api.mount({ a_remounted_api => 'with_conditional' }, with: { mount_sometimes: true })
          root_api.mount({ a_remounted_api => 'without_conditional' }, with: { mount_sometimes: false })

          get '/with_conditional/always'
          expect(last_response.body).to eq 'success'

          get '/with_conditional/sometimes'
          expect(last_response.body).to eq 'sometimes'

          get '/without_conditional/always'
          expect(last_response.body).to eq 'success'

          get '/without_conditional/sometimes'
          expect(last_response.status).to eq 404
        end
      end

      context 'when executing a custom block on mount' do
        subject(:a_remounted_api) do
          Class.new(Grape::API) do
            get 'always' do
              'success'
            end

            mounted do
              configuration[:endpoints].each do |endpoint_name, endpoint_response|
                get endpoint_name do
                  endpoint_response
                end
              end
            end
          end
        end

        it 'mounts the endpoints only when configured to do so' do
          root_api.mount a_remounted_api, with: { endpoints: { 'api_name' => 'api_response' } }
          get 'api_name'
          expect(last_response.body).to eq 'api_response'
        end
      end

      context 'when the configuration is part of the arguments of a method' do
        subject(:a_remounted_api) do
          Class.new(Grape::API) do
            get configuration[:endpoint_name] do
              'success'
            end
          end
        end

        it 'mounts the endpoint in the location it is configured' do
          root_api.mount a_remounted_api, with: { endpoint_name: 'some_location' }
          get '/some_location'
          expect(last_response.body).to eq 'success'

          get '/different_location'
          expect(last_response.status).to eq 404

          root_api.mount a_remounted_api, with: { endpoint_name: 'new_location' }
          get '/new_location'
          expect(last_response.body).to eq 'success'
        end

        context 'when the configuration is the value in a key-arg pair' do
          subject(:a_remounted_api) do
            Class.new(Grape::API) do
              version 'v1', using: :param, parameter: configuration[:version_param]
              get 'endpoint' do
                'version 1'
              end

              version 'v2', using: :param, parameter: configuration[:version_param]
              get 'endpoint' do
                'version 2'
              end
            end
          end

          it 'takes the param from the configuration' do
            root_api.mount a_remounted_api, with: { version_param: 'param_name' }

            get '/endpoint?param_name=v1'
            expect(last_response.body).to eq 'version 1'

            get '/endpoint?param_name=v2'
            expect(last_response.body).to eq 'version 2'

            get '/endpoint?wrong_param_name=v2'
            expect(last_response.body).to eq 'version 1'
          end
        end
      end

      context 'on the DescSCope' do
        subject(:a_remounted_api) do
          Class.new(Grape::API) do
            desc 'The description of this' do
              tags ['not_configurable_tag', configuration[:a_configurable_tag]]
            end
            get 'location' do
              'success'
            end
          end
        end

        it 'mounts the endpoint with the appropiate tags' do
          root_api.mount({ a_remounted_api => 'integer' }, with: { a_configurable_tag: 'a configured tag' })
        end
      end

      context 'on the ParamScope' do
        subject(:a_remounted_api) do
          Class.new(Grape::API) do
            params do
              requires configuration[:required_param], type: configuration[:required_type]
            end

            get 'location' do
              'success'
            end
          end
        end

        it 'mounts the endpoint in the location it is configured' do
          root_api.mount({ a_remounted_api => 'string' }, with: { required_param: 'param_key', required_type: String })
          root_api.mount({ a_remounted_api => 'integer' }, with: { required_param: 'param_integer', required_type: Integer })

          get '/string/location', param_key: 'a'
          expect(last_response.body).to eq 'success'

          get '/string/location', param_integer: 1
          expect(last_response.status).to eq 400

          get '/integer/location', param_integer: 1
          expect(last_response.body).to eq 'success'

          get '/integer/location', param_integer: 'a'
          expect(last_response.status).to eq 400
        end

        context 'on dynamic checks' do
          subject(:a_remounted_api) do
            Class.new(Grape::API) do
              params do
                optional :restricted_values, values: -> { [configuration[:allowed_value], 'always'] }
              end

              get 'location' do
                'success'
              end
            end
          end

          it 'can read the configuration on lambdas' do
            root_api.mount a_remounted_api, with: { allowed_value: 'sometimes' }
            get '/location', restricted_values: 'always'
            expect(last_response.body).to eq 'success'
            get '/location', restricted_values: 'sometimes'
            expect(last_response.body).to eq 'success'
            get '/location', restricted_values: 'never'
            expect(last_response.status).to eq 400
          end
        end
      end

      context 'when the configuration is read within a namespace' do
        before do
          a_remounted_api.namespace 'api' do
            get "/#{configuration[:path]}" do
              '10 votes'
            end
          end
          root_api.mount a_remounted_api, with: { path: 'votes' }
          root_api.mount a_remounted_api, with: { path: 'scores' }
        end

        it 'will use the dynamic configuration on all routes' do
          get 'api/votes'
          expect(last_response.body).to eql '10 votes'
          get 'api/scores'
          expect(last_response.body).to eql '10 votes'
        end
      end

      context 'when the configuration is read in a helper' do
        subject(:a_remounted_api) do
          Class.new(Grape::API) do
            helpers do
              def printed_response
                configuration[:some_value]
              end
            end

            get 'location' do
              printed_response
            end
          end
        end

        it 'will use the dynamic configuration on all routes' do
          root_api.mount(a_remounted_api, with: { some_value: 'response value' })

          get '/location'
          expect(last_response.body).to eq 'response value'
        end
      end

      context 'when the configuration is read within the response block' do
        subject(:a_remounted_api) do
          Class.new(Grape::API) do
            get 'location' do
              configuration[:some_value]
            end
          end
        end

        it 'will use the dynamic configuration on all routes' do
          root_api.mount(a_remounted_api, with: { some_value: 'response value' })

          get '/location'
          expect(last_response.body).to eq 'response value'
        end
      end
    end
  end
end
