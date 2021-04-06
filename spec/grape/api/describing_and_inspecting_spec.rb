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

  class CustomKeyExampleMount < Grape::API
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
    mount CustomKeyExampleMount
  end
end

describe Grape::API do
  let(:description) { 'Includes custom settings.' }
  let(:custom) { { key: 'value' } }

  shared_examples 'same_custom_key_and_value' do
    it 'can have same custom key and value' do
      subject.each do |settings|
        expect(settings[:description]).to eq({ description: 'Includes custom settings.' })
        expect(settings[:custom]).to eq({ key: 'value' })
      end
    end
  end

  context 'independent' do
    subject { DescribingAndInspectingSpec::CustomKeyExample.routes.map(&:settings) }
    include_examples 'same_custom_key_and_value'
  end

  context 'on mount' do
    subject { DescribingAndInspectingSpec::Main.routes.map(&:settings) }
    include_examples 'same_custom_key_and_value'
  end
end
