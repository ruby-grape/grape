# frozen_string_literal: true

require 'spec_helper'
require 'shared/versioning_examples'

describe Grape::API::Instance do
  subject(:an_instance) do
    Class.new(Grape::API::Instance) do
      namespace :some_namespace do
        get 'some_endpoint' do
          'success'
        end
      end
    end
  end

  let(:root_api) do
    to_mount = an_instance
    Class.new(Grape::API) do
      mount to_mount
    end
  end

  def app
    root_api
  end

  context 'when an instance is mounted on the root' do
    it 'can call the instance endpoint' do
      get '/some_namespace/some_endpoint'
      expect(last_response.body).to eq 'success'
    end
  end

  context 'when an instance is the root' do
    let(:root_api) do
      to_mount = an_instance
      Class.new(Grape::API::Instance) do
        mount to_mount
      end
    end

    it 'can call the instance endpoint' do
      get '/some_namespace/some_endpoint'
      expect(last_response.body).to eq 'success'
    end
  end

  context 'top level setting' do
    it 'does not inherit settings from the superclass (Grape::API::Instance)' do
      expect(an_instance.top_level_setting.parent).to be_nil
    end
  end
end
