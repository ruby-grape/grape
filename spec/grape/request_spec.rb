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
        described_class.new(env, build_params_with: :hash)
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

    context 'when rack_params raises an EOF error' do
      before do
        allow(request).to receive(:rack_params).and_raise(EOFError)
      end

      let(:message) { Grape::Exceptions::EmptyMessageBody.new(nil).to_s }

      it 'raises an Grape::Exceptions::EmptyMessageBody' do
        expect { request.params }.to raise_error(Grape::Exceptions::EmptyMessageBody, message)
      end
    end

    context 'when rack_params raises a Rack::Multipart::MultipartPartLimitError' do
      before do
        allow(request).to receive(:rack_params).and_raise(Rack::Multipart::MultipartPartLimitError)
      end

      let(:message) { Grape::Exceptions::TooManyMultipartFiles.new(Rack::Utils.multipart_part_limit).to_s }

      it 'raises an Rack::Multipart::MultipartPartLimitError' do
        expect { request.params }.to raise_error(Grape::Exceptions::TooManyMultipartFiles, message)
      end
    end

    context 'when rack_params raises a Rack::Multipart::MultipartTotalPartLimitError' do
      before do
        allow(request).to receive(:rack_params).and_raise(Rack::Multipart::MultipartTotalPartLimitError)
      end

      let(:message) { Grape::Exceptions::TooManyMultipartFiles.new(Rack::Utils.multipart_part_limit).to_s }

      it 'raises an Rack::Multipart::MultipartPartLimitError' do
        expect { request.params }.to raise_error(Grape::Exceptions::TooManyMultipartFiles, message)
      end
    end

    context 'when rack_params raises a Rack::QueryParser::ParamsTooDeepError' do
      before do
        allow(request).to receive(:rack_params).and_raise(Rack::QueryParser::ParamsTooDeepError)
      end

      let(:message) { Grape::Exceptions::TooDeepParameters.new(Rack::Utils.param_depth_limit).to_s }

      it 'raises a Grape::Exceptions::TooDeepParameters' do
        expect { request.params }.to raise_error(Grape::Exceptions::TooDeepParameters, message)
      end
    end

    context 'when rack_params raises a Rack::Utils::ParameterTypeError' do
      before do
        allow(request).to receive(:rack_params).and_raise(Rack::Utils::ParameterTypeError)
      end

      let(:message) { Grape::Exceptions::ConflictingTypes.new.to_s }

      it 'raises a Grape::Exceptions::ConflictingTypes' do
        expect { request.params }.to raise_error(Grape::Exceptions::ConflictingTypes, message)
      end
    end

    context 'when rack_params raises a Rack::Utils::InvalidParameterError' do
      before do
        allow(request).to receive(:rack_params).and_raise(Rack::Utils::InvalidParameterError)
      end

      let(:message) { Grape::Exceptions::InvalidParameters.new.to_s }

      it 'raises an Rack::Multipart::MultipartPartLimitError' do
        expect { request.params }.to raise_error(Grape::Exceptions::InvalidParameters, message)
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
