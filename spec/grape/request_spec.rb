# frozen_string_literal: true

describe Grape::Request do
  let(:default_method) { Rack::GET }
  let(:default_params) { {} }
  let(:default_options) do
    {
      method: method,
      params: params
    }
  end
  let(:default_env) do
    Rack::MockRequest.env_for('/', options)
  end
  let(:method) { default_method }
  let(:params) { default_params }
  let(:options) { default_options }
  let(:env) { default_env }

  let(:request) do
    described_class.new(env)
  end

  describe '#params' do
    let(:params) do
      {
        a: '123',
        b: 'xyz'
      }
    end

    it 'by default returns stringified parameter keys' do
      expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new('a' => '123', 'b' => 'xyz'))
    end

    context 'when build_params_with: Grape::Extensions::Hash::ParamBuilder is specified' do
      let(:request) do
        described_class.new(env, build_params_with: Grape::Extensions::Hash::ParamBuilder)
      end

      it 'returns symbolized params' do
        expect(request.params).to eq(a: '123', b: 'xyz')
      end
    end

    describe 'with grape.routing_args' do
      let(:options) do
        default_options.merge('grape.routing_args' => routing_args)
      end
      let(:routing_args) do
        {
          version: '123',
          route_info: '456',
          c: 'ccc'
        }
      end

      it 'cuts version and route_info' do
        expect(request.params).to eq(ActiveSupport::HashWithIndifferentAccess.new(a: '123', b: 'xyz', c: 'ccc'))
      end
    end
  end

  describe '#headers' do
    let(:options) do
      default_options.merge(request_headers)
    end

    describe 'with http headers in env' do
      let(:request_headers) do
        {
          'HTTP_X_GRAPE_IS_COOL' => 'yeah'
        }
      end
      let(:x_grape_is_cool_header) do
        'x-grape-is-cool'
      end

      it 'cuts HTTP_ prefix and capitalizes header name words' do
        expect(request.headers).to eq(x_grape_is_cool_header => 'yeah')
      end
    end

    describe 'with non-HTTP_* stuff in env' do
      let(:request_headers) do
        {
          'HTP_X_GRAPE_ENTITY_TOO' => 'but now we are testing Grape'
        }
      end

      it 'does not include them' do
        expect(request.headers).to eq({})
      end
    end

    describe 'with symbolic header names' do
      let(:request_headers) do
        {
          HTTP_GRAPE_LIKES_SYMBOLIC: 'it is true'
        }
      end
      let(:env) do
        default_env.merge(request_headers)
      end
      let(:grape_likes_symbolic_header) do
        'grape-likes-symbolic'
      end

      it 'converts them to string' do
        expect(request.headers).to eq(grape_likes_symbolic_header => 'it is true')
      end
    end
  end
end
