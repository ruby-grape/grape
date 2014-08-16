require 'spec_helper'

module Grape
  module DSL
    module InsideRouteSpec
      class Dummy
        include Grape::DSL::InsideRoute

        attr_reader :env, :request, :settings

        def initialize
          @env = {}
          @header = {}
          @settings = Grape::Util::HashStack.new
        end
      end
    end

    describe Endpoint do
      subject { InsideRouteSpec::Dummy.new }

      describe '#version' do
        it 'defaults to nil' do
          expect(subject.version).to be nil
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
            subject.settings[:default_error_status] = 500
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
        ['GET', 'PUT', 'DELETE', 'OPTIONS'].each do |method|
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

        it 'returns status set' do
          subject.status 501
          expect(subject.status).to eq 501
        end
      end

      describe '#header' do
        describe 'set' do
          before do
            subject.header 'Name', 'Value'
          end

          it 'returns value' do
            expect(subject.header['Name']).to eq 'Value'
            expect(subject.header('Name')).to eq 'Value'
          end
        end

        it 'returns nil' do
          expect(subject.header['Name']).to be nil
          expect(subject.header('Name')).to be nil
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
          expect(subject.content_type).to be nil
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

        it 'returns default' do
          expect(subject.body).to be nil
        end
      end

      describe '#route' do
        before do
          subject.env['rack.routing_args'] = {}
          subject.env['rack.routing_args'][:route_info] = 'dummy'
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
      end

      describe '#declared' do
        # see endpoint_spec.rb#declared for spec coverage

        it 'returns an empty hash' do
          expect(subject.declared({})).to eq({})
        end
      end
    end
  end
end
