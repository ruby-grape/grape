require 'spec_helper'

describe Grape::Validations::SplitValidator do
  subject do
    Class.new(Grape::API)
  end

  def app
    subject
  end

  it 'split String into an Array' do
    subject.params do
      requires :name, split: /|/
    end
    subject.get do
      params[:name].class
    end

    get '', name: 'foo|bar'
    expect(last_response.status).to eq(200)
    expect(last_response.body).to eq('Array')
  end
end
