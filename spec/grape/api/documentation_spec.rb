# frozen_string_literal: true

require 'spec_helper'

describe Grape::API do
  subject { Class.new(described_class) }

  let(:app) { subject }

  context 'an endpoint with documentation' do
    it 'documents parameters' do
      subject.params do
        requires 'price', type: Float, desc: 'Sales price'
      end
      subject.get '/'

      expect(subject.routes.first.params['price']).to eq(required: true,
                                                         type: 'Float',
                                                         desc: 'Sales price')
    end

    it 'allows documentation with a hash' do
      documentation = { example: 'Joe' }

      subject.params do
        requires 'first_name', documentation: documentation
      end
      subject.get '/'

      expect(subject.routes.first.params['first_name'][:documentation]).to eq(documentation)
    end
  end

  context 'an endpoint without documentation' do
    before do
      subject.do_not_document!

      subject.params do
        requires :city, type: String, desc: 'Should be ignored'
        optional :postal_code, type: Integer
      end
      subject.post '/' do
        declared(params).to_json
      end
    end

    it 'does not document parameters for the endpoint' do
      expect(subject.routes.first.params).to eq({})
    end

    it 'still declares params internally' do
      data = { city: 'Berlin', postal_code: 10_115 }

      post '/', data

      expect(last_response.body).to eq(data.to_json)
    end
  end
end
