require 'spec_helper'

describe Grape::API do
  include Rack::Test::Methods

  subject {
    Class.new(Grape::API) do
      prefix 'gcapi'

      resources :testing do
        get do
          "Hello World"
        end
      end
    end
  }

  def app
    subject
  end

  def count_references(array_of_classes)
    counts = Hash.new
    array_of_classes.each do |klass|
      count = 0
      ObjectSpace.each_object(klass) do |o|
        count += 1
      end
      counts[klass.to_s] = count
    end
    counts
  end

  def concerns
    [
      Grape::Endpoint,
      Grape::Util::HashStack,
      Regexp
    ]
  end

  context "when performing a single call against the endpoint" do
    it 'is adding an uncollectable reference to Grape::Endpoint' do
      GC.start
      pre_test_counts = count_references concerns

      get 'gcapi/testing'
      expect(last_response.body).to eql "Hello World"

      GC.start
      post_test_counts = count_references concerns

      expect(post_test_counts).to eql pre_test_counts
    end
  end

  context "when performing multiple calls against the endpoint" do
    it 'is dropping that extra reference to Grape::Endpoint' do
      GC.start
      pre_test_counts = count_references concerns

      get 'gcapi/testing'
      expect(last_response.body).to eql "Hello World"

      get 'gcapi/testing/hello' # bad call to endpoint

      GC.start
      post_test_counts = count_references concerns

      expect(post_test_counts).to eql pre_test_counts
    end

    it 'is not dropping that extra reference to Grape::Endpoint' do
      GC.start
      pre_test_counts = count_references concerns

      get 'gcapi/testing'
      expect(last_response.body).to eql "Hello World"

      get 'gcapi/testing' # repeat first call

      GC.start
      post_test_counts = count_references concerns

      expect(post_test_counts).to eql pre_test_counts
    end
  end
end
