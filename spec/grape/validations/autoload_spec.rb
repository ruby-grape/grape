require 'spec_helper'

describe Grape::Validations::Autoload do
  let(:fake_api) { stub_const('MyApp::Api::V2::Resourses', Class.new) }
  let(:api_base_path) { 'my_app/api/v2' }

  subject { described_class.new(fake_api) }

  describe '#try_load' do
    let(:validator_name) { :custom }
    let(:validator_path_for_api) { "#{api_base_path}/validators/#{validator_name}" }
    let(:common_validator_path) { "api/validators/#{validator_name}" }

    context 'ActiveSupport::Dependencies is undefined' do
      it { expect(subject.try_load(:some_validator)).to be_nil }
    end

    context 'ActiveSupport::Dependencies is defined' do
      let!(:active_support_dependencies) { stub_const('::ActiveSupport::Dependencies', Class.new) }

      context 'validator search paths' do
        let!(:custom_validator_for_api) { stub_const('MyApp::Api::V2::Validators::Custom', Class.new) }
        let!(:common_custom_validator) { stub_const('Api::Validators::Custom', Class.new) }

        it 'requires the dependency using file path based on the api namespace' do
          expect(subject).to receive(:require_dependency).with(validator_path_for_api)
          subject.try_load(validator_name)
        end

        context 'the dependency based on the api namespace is not found' do
          before do
            allow(subject).to receive(:require_dependency).with(validator_path_for_api).and_raise(LoadError)
          end

          it 'requires the dependency from the default path "api/validators"' do
            expect(subject).to receive(:require_dependency).with(common_validator_path)
            subject.try_load(validator_name)
          end
        end
      end

      context 'the required dependency is not found' do
        before do
          allow(subject).to receive(:require_dependency).and_raise(LoadError)
        end

        it { expect(subject.try_load(:some_validator)).to be_nil }
      end

      context 'the required dependency is found' do
        let!(:expected_validator_constant) { stub_const('MyApp::Api::V2::Validators::Custom', Class.new) }
        let(:validator_name) { :custom }

        before do
          allow(subject).to receive(:require_dependency).with("my_app/api/v2/validators/#{validator_name}").and_return(true)
        end

        it 'returns the validator constant' do
          expect(subject.try_load(validator_name)).to eq(expected_validator_constant)
        end

        context 'using the default path' do
          let!(:expected_validator_constant) { stub_const('Api::Validators::MyValidator', Class.new) }
          let(:validator_name) { :my_validator }

          before do
            allow(subject).to receive(:require_dependency).with("my_app/api/v2/validators/#{validator_name}").and_raise(LoadError)
            allow(subject).to receive(:require_dependency).with("api/validators/#{validator_name}").and_return(true)
          end

          it 'returns the validator constant' do
            expect(subject.try_load(validator_name)).to eq(expected_validator_constant)
          end
        end

        it 'sets ActiveSupport::Dependencies "before_remove_const" callback to the parent constant' do
          subject.try_load(validator_name)
          expect(MyApp).to respond_to(:before_remove_const)
        end
      end
    end
  end
end
