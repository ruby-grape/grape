# frozen_string_literal: true

module Grape
  module DSL
    module InsideRouteSpec
      class Dummy
        include Grape::DSL::InsideRoute

        attr_reader :env, :request, :new_settings

        def initialize
          @env = {}
          @header = {}
          @new_settings = { namespace_inheritable: {}, namespace_stackable: {} }
        end
      end
    end
  end
end

describe Grape::Endpoint do
  subject { Grape::DSL::InsideRouteSpec::Dummy.new }

  describe '#version' do
    it 'defaults to nil' do
      expect(subject.version).to be_nil
    end

    it 'returns env[api.version]' do
      subject.env['api.version'] = 'dummy'
      expect(subject.version).to eq 'dummy'
    end
  end

  describe '#error!' do
    it 'throws :error' do
      expect { subject.error! 'Not Found', 404 }.to throw_symbol(:error)
    end

    describe 'thrown' do
      before do
        catch(:error) { subject.error! 'Not Found', 404 }
      end

      it 'sets status' do
        expect(subject.status).to eq 404
      end
    end

    describe 'default_error_status' do
      before do
        subject.namespace_inheritable(:default_error_status, 500)
        catch(:error) { subject.error! 'Unknown' }
      end

      it 'sets status to default_error_status' do
        expect(subject.status).to eq 500
      end
    end

    # self.status(status || settings[:default_error_status])
    # throw :error, message: message, status: self.status, headers: headers
  end

  describe '#redirect' do
    describe 'default' do
      before do
        subject.redirect '/'
      end

      it 'sets status to 302' do
        expect(subject.status).to eq 302
      end

      it 'sets location header' do
        expect(subject.header['Location']).to eq '/'
      end
    end

    describe 'permanent' do
      before do
        subject.redirect '/', permanent: true
      end

      it 'sets status to 301' do
        expect(subject.status).to eq 301
      end

      it 'sets location header' do
        expect(subject.header['Location']).to eq '/'
      end
    end
  end

  describe '#status' do
    %w[GET PUT OPTIONS].each do |method|
      it 'defaults to 200 on GET' do
        request = Grape::Request.new(Rack::MockRequest.env_for('/', method: method))
        expect(subject).to receive(:request).and_return(request)
        expect(subject.status).to eq 200
      end
    end

    it 'defaults to 201 on POST' do
      request = Grape::Request.new(Rack::MockRequest.env_for('/', method: 'POST'))
      expect(subject).to receive(:request).and_return(request)
      expect(subject.status).to eq 201
    end

    it 'defaults to 204 on DELETE' do
      request = Grape::Request.new(Rack::MockRequest.env_for('/', method: 'DELETE'))
      expect(subject).to receive(:request).and_return(request)
      expect(subject.status).to eq 204
    end

    it 'defaults to 200 on DELETE with a body present' do
      request = Grape::Request.new(Rack::MockRequest.env_for('/', method: 'DELETE'))
      subject.body 'content here'
      expect(subject).to receive(:request).and_return(request)
      expect(subject.status).to eq 200
    end

    it 'returns status set' do
      subject.status 501
      expect(subject.status).to eq 501
    end

    it 'accepts symbol for status' do
      subject.status :see_other
      expect(subject.status).to eq 303
    end

    it 'raises error if unknow symbol is passed' do
      expect { subject.status :foo_bar }
        .to raise_error(ArgumentError, 'Status code :foo_bar is invalid.')
    end

    it 'accepts unknown Integer status codes' do
      expect { subject.status 210 }.not_to raise_error
    end

    it 'raises error if status is not a integer or symbol' do
      expect { subject.status Object.new }
        .to raise_error(ArgumentError, 'Status code must be Integer or Symbol.')
    end
  end

  describe '#return_no_content' do
    it 'sets the status code and body' do
      subject.return_no_content
      expect(subject.status).to eq 204
      expect(subject.body).to eq ''
    end
  end

  describe '#content_type' do
    describe 'set' do
      before do
        subject.content_type 'text/plain'
      end

      it 'returns value' do
        expect(subject.content_type).to eq 'text/plain'
      end
    end

    it 'returns default' do
      expect(subject.content_type).to be_nil
    end
  end

  describe '#cookies' do
    it 'returns an instance of Cookies' do
      expect(subject.cookies).to be_a Grape::Cookies
    end
  end

  describe '#body' do
    describe 'set' do
      before do
        subject.body 'body'
      end

      it 'returns value' do
        expect(subject.body).to eq 'body'
      end
    end

    describe 'false' do
      before do
        subject.body false
      end

      it 'sets status to 204' do
        expect(subject.body).to eq ''
        expect(subject.status).to eq 204
      end
    end

    it 'returns default' do
      expect(subject.body).to be_nil
    end
  end

  describe '#file' do
    before do
      allow(subject).to receive(:warn)
    end

    describe 'set' do
      context 'as file path' do
        let(:file_path) { '/some/file/path' }

        it 'emits a warning that this method is deprecated' do
          expect(subject).to receive(:warn).with(/Use sendfile or stream/)

          subject.file file_path
        end

        it 'forwards the call to sendfile' do
          expect(subject).to receive(:sendfile).with(file_path)

          subject.file file_path
        end
      end

      context 'as object (backward compatibility)' do
        let(:file_object) { double('StreamerObject', each: nil) }

        it 'emits a warning that this method is deprecated' do
          expect(subject).to receive(:warn).with(/Use stream to use a Stream object/)

          subject.file file_object
        end

        it 'forwards the call to stream' do
          expect(subject).to receive(:stream).with(file_object)

          subject.file file_object
        end
      end
    end

    describe 'get' do
      it 'emits a warning that this method is deprecated' do
        expect(subject).to receive(:warn).with(/Use sendfile or stream/)

        subject.file
      end

      it 'fowards call to sendfile' do
        expect(subject).to receive(:sendfile)

        subject.file
      end
    end
  end

  describe '#sendfile' do
    describe 'set' do
      context 'as file path' do
        let(:file_path) { '/some/file/path' }

        let(:file_response) do
          file_body = Grape::ServeStream::FileBody.new(file_path)
          Grape::ServeStream::StreamResponse.new(file_body)
        end

        before do
          subject.header 'Cache-Control', 'cache'
          subject.header 'Content-Length', 123
          subject.header 'Transfer-Encoding', 'base64'
        end

        it 'sends no deprecation warnings' do
          expect(subject).not_to receive(:warn)

          subject.sendfile file_path
        end

        it 'returns value wrapped in StreamResponse' do
          subject.sendfile file_path

          expect(subject.sendfile).to eq file_response
        end

        it 'does not change the Cache-Control header' do
          subject.sendfile file_path

          expect(subject.header['Cache-Control']).to eq 'cache'
        end

        it 'does not change the Content-Length header' do
          subject.sendfile file_path

          expect(subject.header['Content-Length']).to eq 123
        end

        it 'does not change the Transfer-Encoding header' do
          subject.sendfile file_path

          expect(subject.header['Transfer-Encoding']).to eq 'base64'
        end
      end

      context 'as object' do
        let(:file_object) { double('StreamerObject', each: nil) }

        it 'raises an error that only a file path is supported' do
          expect { subject.sendfile file_object }.to raise_error(ArgumentError, /Argument must be a file path/)
        end
      end
    end

    it 'returns default' do
      expect(subject.sendfile).to be_nil
    end
  end

  describe '#stream' do
    describe 'set' do
      context 'as a file path' do
        let(:file_path) { '/some/file/path' }

        let(:file_response) do
          file_body = Grape::ServeStream::FileBody.new(file_path)
          Grape::ServeStream::StreamResponse.new(file_body)
        end

        before do
          subject.header 'Cache-Control', 'cache'
          subject.header 'Content-Length', 123
          subject.header 'Transfer-Encoding', 'base64'
        end

        it 'emits no deprecation warnings' do
          expect(subject).not_to receive(:warn)

          subject.stream file_path
        end

        it 'returns file body wrapped in StreamResponse' do
          subject.stream file_path

          expect(subject.stream).to eq file_response
        end

        it 'sets Cache-Control header to no-cache' do
          subject.stream file_path

          expect(subject.header['Cache-Control']).to eq 'no-cache'
        end

        it 'does not change Cache-Control header' do
          subject.stream

          expect(subject.header['Cache-Control']).to eq 'cache'
        end

        it 'sets Content-Length header to nil' do
          subject.stream file_path

          expect(subject.header['Content-Length']).to be_nil
        end

        it 'sets Transfer-Encoding header to nil' do
          subject.stream file_path

          expect(subject.header['Transfer-Encoding']).to be_nil
        end
      end

      context 'as a stream object' do
        let(:stream_object) { double('StreamerObject', each: nil) }

        let(:stream_response) do
          Grape::ServeStream::StreamResponse.new(stream_object)
        end

        before do
          subject.header 'Cache-Control', 'cache'
          subject.header 'Content-Length', 123
          subject.header 'Transfer-Encoding', 'base64'
        end

        it 'emits no deprecation warnings' do
          expect(subject).not_to receive(:warn)

          subject.stream stream_object
        end

        it 'returns value wrapped in StreamResponse' do
          subject.stream stream_object

          expect(subject.stream).to eq stream_response
        end

        it 'sets Cache-Control header to no-cache' do
          subject.stream stream_object

          expect(subject.header['Cache-Control']).to eq 'no-cache'
        end

        it 'sets Content-Length header to nil' do
          subject.stream stream_object

          expect(subject.header['Content-Length']).to be_nil
        end

        it 'sets Transfer-Encoding header to nil' do
          subject.stream stream_object

          expect(subject.header['Transfer-Encoding']).to be_nil
        end
      end

      context 'as a non-stream object' do
        let(:non_stream_object) { double('NonStreamerObject') }

        it 'raises an error that the object must implement :each' do
          expect { subject.stream non_stream_object }.to raise_error(ArgumentError, /:each/)
        end
      end
    end

    it 'returns default' do
      expect(subject.stream).to be_nil
      expect(subject.header['Cache-Control']).to be_nil
    end
  end

  describe '#route' do
    before do
      subject.env['grape.routing_args'] = {}
      subject.env['grape.routing_args'][:route_info] = 'dummy'
    end

    it 'returns route_info' do
      expect(subject.route).to eq 'dummy'
    end
  end

  describe '#present' do
    # see entity_spec.rb for entity representation spec coverage

    describe 'dummy' do
      before do
        subject.present 'dummy'
      end

      it 'presents dummy object' do
        expect(subject.body).to eq 'dummy'
      end
    end

    describe 'with' do
      describe 'entity' do
        let(:entity_mock) do
          entity_mock = Object.new
          allow(entity_mock).to receive(:represent).and_return('dummy')
          entity_mock
        end

        describe 'instance' do
          before do
            subject.present 'dummy', with: entity_mock
          end

          it 'presents dummy object' do
            expect(subject.body).to eq 'dummy'
          end
        end
      end
    end

    describe 'multiple entities' do
      let(:entity_mock_one) do
        entity_mock_one = Object.new
        allow(entity_mock_one).to receive(:represent).and_return(dummy1: 'dummy1')
        entity_mock_one
      end

      let(:entity_mock_two) do
        entity_mock_two = Object.new
        allow(entity_mock_two).to receive(:represent).and_return(dummy2: 'dummy2')
        entity_mock_two
      end

      describe 'instance' do
        before do
          subject.present 'dummy1', with: entity_mock_one
          subject.present 'dummy2', with: entity_mock_two
        end

        it 'presents both dummy objects' do
          expect(subject.body[:dummy1]).to eq 'dummy1'
          expect(subject.body[:dummy2]).to eq 'dummy2'
        end
      end
    end

    describe 'non mergeable entity' do
      let(:entity_mock_one) do
        entity_mock_one = Object.new
        allow(entity_mock_one).to receive(:represent).and_return(dummy1: 'dummy1')
        entity_mock_one
      end

      let(:entity_mock_two) do
        entity_mock_two = Object.new
        allow(entity_mock_two).to receive(:represent).and_return('not a hash')
        entity_mock_two
      end

      describe 'instance' do
        it 'fails' do
          subject.present 'dummy1', with: entity_mock_one
          expect do
            subject.present 'dummy2', with: entity_mock_two
          end.to raise_error ArgumentError, 'Representation of type String cannot be merged.'
        end
      end
    end
  end

  describe '#declared' do
    # see endpoint_spec.rb#declared for spec coverage

    it 'is not available by default' do
      expect { subject.declared({}) }.to raise_error(
        Grape::DSL::InsideRoute::MethodNotYetAvailable
      )
    end
  end
end
