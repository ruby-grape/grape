# frozen_string_literal: true

# see https://github.com/ruby-grape/grape/issues/1975

require 'spec_helper'

module NestedRescueFromSpec
  class Alpacas < Grape::API
    resource :alpacas do
      rescue_from :all do
        error_response(status: 200)
      end

      get do
        { count_alpacas: 1 / 0 }
      end
    end
  end

  class Main < Grape::API
    rescue_from ZeroDivisionError do
      error_response(status: 500)
    end

    mount NestedRescueFromSpec::Alpacas
  end
end

describe Grape::API do
  subject { NestedRescueFromSpec::Main }

  def app
    subject
  end

  it 'calls the inner rescue_from :all from Alpacas class' do
    get '/alpacas'
    expect(last_response.status).to eql 200
  end
end
