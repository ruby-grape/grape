# frozen_string_literal: true

require 'spec_helper'

# @see https://github.com/ruby-grape/grape#describing-and-inspecting-an-api
#
# @see https://github.com/ruby-grape/grape/issues/2173
module DescribingAndInspectingSpec

  class CustomKeyExample < Grape::API
    desc 'Includes custom settings.'
    route_setting :custom, key: 'value'
    get '/api1' do
      status 200
    end

    desc 'Includes custom settings.'
    route_setting :custom, key: 'value'
    get '/api2' do
      status 200
    end
  end

  class Main < Grape::API
    mount CustomKeyExample
  end

end

describe Grape::API do
  subject { DescribingAndInspectingSpec::Main.routes.map(&:settings) }

  let(:description) { 'Includes custom settings.' }
  let(:custom) { { key: 'value' } }

  it 'can have same custom key and value' do
    subject.each do |settings|
      expect(settings[:description]).to eq({ description: 'Includes custom settings.' })
      expect(settings[:custom]).to eq({ key: 'value' })
    end
  end
end
