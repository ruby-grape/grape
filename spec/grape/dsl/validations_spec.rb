require 'spec_helper'

module Grape
  module DSL
    module ValidationsSpec
      class Dummy
        include Grape::DSL::Validations
      end
    end

    describe Validations do
      subject { Class.new(ValidationsSpec::Dummy) }

      xdescribe '.reset_validations!' do
        it 'does some thing'
      end

      xdescribe '.params' do
        it 'does some thing'
      end

      xdescribe '.document_attribute' do
        it 'does some thing'
      end
    end
  end
end
