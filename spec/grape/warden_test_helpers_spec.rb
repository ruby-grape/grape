require 'spec_helper'

FailureApp = ->(env) { [401, {}, ['']] }

class APIEvaluatedBeforeTests < Grape::API
  use(Warden::Manager) { |manager| manager.failure_app = FailureApp }

  before { env.fetch('warden').authenticate! }

  get '/'
end

describe Warden::Test::Helpers do
  def app
    subject
  end

  describe '#login_as' do
    before { login_as(:user) }

    context 'API evaluated before tests' do
      subject { APIEvaluatedBeforeTests }

      it 'logs in' do
        get '/'
        expect(last_response).to be_ok
      end
    end

    context 'API evaluated after tests' do
      let(:api_evaluated_after_tests) do
        Class.new(Grape::API) do
          use(Warden::Manager) { |manager| manager.failure_app = FailureApp }

          before { env.fetch('warden').authenticate! }

          get '/'
        end
      end

      subject { api_evaluated_after_tests }

      it 'logs in' do
        get '/'
        expect(last_response).to be_ok
      end
    end
  end
end
