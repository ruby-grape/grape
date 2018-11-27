require 'spec_helper'

describe 'A named API' do
  NamedAPI = Class.new(Grape::API) do
    get 'test' do
      'response'
    end
  end

  subject(:api_name) { NamedAPI.endpoints.last.options[:for].to_s }

  it 'can access the name of the API' do
    expect(api_name).to eq 'NamedAPI'
  end
end
