require 'spec_helper'

describe Grape::API do
  let(:error_header) do
    Class.new(Grape::API) do
      before do
        header 'X-Grape-Before-Header', '1'
      end
      after do
        header 'X-Grape-After-Header', '1'
      end
      get '/success' do
        header 'X-Grape-Returns-Error', '1'
      end
      get '/error' do
        header 'X-Grape-Returns-Error', '1'
        error!(success: false)
      end
    end
  end

  subject do
    ErrorHeader = error_header unless defined?(ErrorHeader)
    Class.new(Grape::API) do
      format :json
      mount ErrorHeader => '/'
    end
  end

  def app
    subject
  end

  it 'should returns all headers on success' do
    get '/success'
    expect(last_response.headers['X-Grape-Returns-Error']).to eq('1')
    expect(last_response.headers['X-Grape-Before-Header']).to eq('1')
    expect(last_response.headers['X-Grape-After-Header']).to eq('1')
  end

  it 'should returns all headers on error' do
    get '/error'
    expect(last_response.headers['X-Grape-Returns-Error']).to eq('1')
    expect(last_response.headers['X-Grape-Before-Header']).to eq('1')
    expect(last_response.headers['X-Grape-After-Header']).to eq('1')
  end
end
