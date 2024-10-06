# frozen_string_literal: true

describe Grape::API do
  subject(:api_name) { NamedAPI.endpoints.last.options[:for].to_s }

  let(:api) do
    Class.new(Grape::API) do
      get 'test' do
        'response'
      end
    end
  end

  let(:name) { 'NamedAPI'}

  before { stub_const(name, api) }

  it 'can access the name of the API' do
    expect(api_name).to eq name
  end
end
