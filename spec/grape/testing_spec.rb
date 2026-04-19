# frozen_string_literal: true

require 'grape/testing'

describe Grape::Testing do
  subject { Class.new(Grape::API) }

  let(:app) { subject }

  describe 'Grape::Endpoint.before_each' do
    after { Grape::Endpoint.reset_before_each }

    it 'is able to override a helper' do
      subject.get('/') { current_user }
      expect { get '/' }.to raise_error(NameError, /undefined local variable or method [`']current_user'/)

      Grape::Endpoint.before_each do |endpoint|
        allow(endpoint).to receive(:current_user).and_return('Bob')
      end

      get '/'
      expect(last_response.body).to eq('Bob')

      Grape::Endpoint.reset_before_each
      expect { get '/' }.to raise_error(NameError, /undefined local variable or method [`']current_user'/)
    end

    it 'is able to stack helpers' do
      subject.get('/') do
        authenticate_user!
        current_user
      end
      expect { get '/' }.to raise_error(NoMethodError, /undefined method [`']authenticate_user!' for/)

      Grape::Endpoint.before_each do |endpoint|
        allow(endpoint).to receive_messages(current_user: 'Bob', authenticate_user!: true)
      end

      get '/'
      expect(last_response.body).to eq('Bob')

      Grape::Endpoint.reset_before_each
      expect { get '/' }.to raise_error(NoMethodError, /undefined method [`']authenticate_user!' for/)
    end
  end
end
