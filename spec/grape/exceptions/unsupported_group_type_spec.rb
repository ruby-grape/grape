# frozen_string_literal: true

require 'shared/deprecated_class_examples'

RSpec.describe Grape::Exceptions::UnsupportedGroupType do
  subject { described_class.new }

  describe '#message' do
    subject { described_class.new.message }

    it { is_expected.to include 'group type must be Array, Hash, JSON or Array[JSON]' }
  end

  describe 'Grape::Exceptions::UnsupportedGroupTypeError' do
    let(:deprecated_class) { Grape::Exceptions::UnsupportedGroupTypeError }

    it_behaves_like 'deprecated class'
  end
end
