# frozen_string_literal: true

describe Grape::Http::Headers do
  subject { last_response.headers }

  describe 'returned headers should all be in lowercase' do
    context 'when setting an header in an API' do
      let(:app) do
        Class.new(Grape::API) do
          get do
            header['GRAPE'] = '1'
            return_no_content
          end
        end
      end

      before { get '/' }

      it { is_expected.to include('grape' => '1') }
    end

    context 'when error!' do
      let(:app) do
        Class.new(Grape::API) do
          rescue_from ArgumentError do
            error!('error!', 500, { 'GRAPE' => '1' })
          end

          get { raise ArgumentError }
        end
      end

      before { get '/' }

      it { is_expected.to include('grape' => '1') }
    end

    context 'when redirect' do
      let(:app) do
        Class.new(Grape::API) do
          get do
            redirect 'https://www.ruby-grape.org/'
          end
        end
      end

      before { get '/' }

      it { is_expected.to include('location' => 'https://www.ruby-grape.org/') }
    end

    context 'when options' do
      let(:app) do
        Class.new(Grape::API) do
          get { return_no_content }
        end
      end

      before { options '/' }

      it { is_expected.to include('allow' => 'OPTIONS, GET, HEAD') }
    end

    context 'when cascade' do
      let(:app) do
        Class.new(Grape::API) do
          version 'v0', using: :path, cascade: true
          get { return_no_content }
        end
      end

      before { get '/v1' }

      it { is_expected.to include('x-cascade' => 'pass') }
    end
  end
end
