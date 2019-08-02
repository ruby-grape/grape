require 'spec_helper'

describe Grape::API::Instance do
  describe 'Boolean constant' do
    subject { Class.new(described_class)::Boolean }
    it 'sets Boolean as a Virtus::Attribute::Boolean' do
      is_expected.to eq Virtus::Attribute::Boolean
    end
  end
end
