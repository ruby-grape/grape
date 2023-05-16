# frozen_string_literal: true

require 'shared/deprecated_class_examples'

RSpec.describe Grape::Exceptions::MissingGroupType do
  describe '#message' do
    subject { described_class.new.message }

    it { is_expected.to include 'group type is required' }
  end

  describe 'Grape::Exceptions::MissingGroupTypeError' do
    let(:deprecated_class) { Grape::Exceptions::MissingGroupTypeError }

    it_behaves_like 'deprecated class'
  end
end
