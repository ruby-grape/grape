require 'spec_helper'
require 'ostruct'

describe Grape::Exceptions::ValidationErrors do
  let(:validation_message) { "FooBar is invalid" }
  let(:validation_error) { OpenStruct.new(params: [validation_message]) }

  context "message" do
    context "is not repeated" do
      let(:error) do
        described_class.new(errors: [validation_error, validation_error])
      end
      subject(:message) { error.message.split(',').map(&:strip) }

      it { expect(message).to include validation_message }
      it { expect(message.size).to eq 1 }
    end
  end

  context 'api' do
    subject { Class.new(Grape::API) }

    def app
      subject
    end

    it 'can return structured json with separate fields' do
      subject.format :json
      subject.rescue_from Grape::Exceptions::ValidationErrors do |e|
        rack_response e.to_json, 400
      end
      subject.params do
        optional :beer
        optional :wine
        optional :juice
        exactly_one_of :beer, :wine, :juice
      end
      subject.get '/exactly_one_of' do
        'exactly_one_of works!'
      end
      get '/exactly_one_of', beer: 'string', wine: 'anotherstring'
      expect(last_response.status).to eq(400)
      expect(JSON.parse(last_response.body)).to eq([
        "params" => ["beer", "wine"],
        "messages" => ["are mutually exclusive"]
      ])
    end
  end
end
