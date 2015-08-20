require 'spec_helper'

module Grape
  describe Request do
    let(:default_method) { 'GET' }
    let(:default_params) { {} }
    let(:default_options) {
      {
        method: method,
        params: params
      }
    }
    let(:default_env) {
      Rack::MockRequest.env_for('/', options)
    }
    let(:method) { default_method }
    let(:params) { default_params }
    let(:options) { default_options }
    let(:env) { default_env }

    let(:request) {
      Grape::Request.new(env)
    }

    describe '#params' do
      let(:params) {
        {
          a: '123',
          b: 'xyz'
        }
      }

      it 'returns params' do
        expect(request.params).to eq('a' => '123', 'b' => 'xyz')
      end

      describe 'with rack.routing_args' do
        let(:options) {
          default_options.merge('rack.routing_args' => routing_args)
        }
        let(:routing_args) {
          {
            version: '123',
            route_info: '456',
            c: 'ccc'
          }
        }

        it 'cuts version and route_info' do
          expect(request.params).to eq('a' => '123', 'b' => 'xyz', 'c' => 'ccc')
        end
      end
    end

    describe '#headers' do
      let(:options) {
        default_options.merge(request_headers)
      }

      describe 'with http headers in env' do
        let(:request_headers) {
          {
            'HTTP_X_GRAPE_IS_COOL' => 'yeah'
          }
        }

        it 'cuts HTTP_ prefix and capitalizes header name words' do
          expect(request.headers).to eq('X-Grape-Is-Cool' => 'yeah')
        end
      end

      describe 'with non-HTTP_* stuff in env' do
        let(:request_headers) {
          {
            'HTP_X_GRAPE_ENTITY_TOO' => 'but now we are testing Grape'
          }
        }

        it 'does not include them' do
          expect(request.headers).to eq({})
        end
      end

      describe 'with symbolic header names' do
        let(:request_headers) {
          {
            HTTP_GRAPE_LIKES_SYMBOLIC: 'it is true'
          }
        }
        let(:env) {
          default_env.merge(request_headers)
        }

        it 'converts them to string' do
          expect(request.headers).to eq('Grape-Likes-Symbolic' => 'it is true')
        end
      end
    end
  end
end
