require 'spec_helper'

describe 'custom validators autoloading based on ActiveSupport::Dependencies' do
  before(:all) do
    require 'active_support/dependencies'
  end

  subject { Class.new(Grape::API) }

  def app
    subject
  end

  shared_examples 'raise an exception for an unknown validator' do |validator_name|
    it 'raises Grape::Exceptions::UnknownValidator' do
      expect {
        subject.params do
          requires :param, validator_name => true
        end
      }.to raise_error(Grape::Exceptions::UnknownValidator)
    end
  end

  context 'autoload paths are defined' do
    before do
      ActiveSupport::Dependencies.autoload_paths << File.expand_path('spec/grape/integration/custom_validators_autoload/')
    end

    it 'load and applies the custom validator if it exists in autoload paths' do
      subject.params do
        requires :param, custom: true
      end
      subject.get do
        params[:param]
      end

      get '/', param: 'some_param'
      expect(last_response.body).to eq 'custom_validated'
    end

    it_behaves_like 'raise an exception for an unknown validator', :not_custom
  end

  context 'autoload paths are empty' do
    before do
      ActiveSupport::Dependencies.autoload_paths = []
    end

    it_behaves_like 'raise an exception for an unknown validator', :some_validator
  end
end
