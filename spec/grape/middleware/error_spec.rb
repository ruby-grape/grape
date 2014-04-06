require 'spec_helper'

describe Grape::Middleware::Error do
  class ErrApp
    class << self
      attr_accessor :error
      attr_accessor :format

      def call(env)
        throw :error, error
      end
    end
  end

  def app
    Rack::Builder.app do
      use Grape::Middleware::Error, default_message: 'Aww, hamburgers.'
      run ErrApp
    end
  end

  it 'sets the status code appropriately' do
    ErrApp.error = { status: 410 }
    get '/'
    expect(last_response.status).to eq(410)
  end

  it 'sets the error message appropriately' do
    ErrApp.error = { message: 'Awesome stuff.' }
    get '/'
    expect(last_response.body).to eq('Awesome stuff.')
  end

  it 'defaults to a 500 status' do
    ErrApp.error = {}
    get '/'
    expect(last_response.status).to eq(500)
  end

  it 'has a default message' do
    ErrApp.error = {}
    get '/'
    expect(last_response.body).to eq('Aww, hamburgers.')
  end
end
