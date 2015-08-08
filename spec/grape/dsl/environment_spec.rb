require 'spec_helper'

module Grape
  module DSL
    module EnvironmentSpec
       class Dummy
         include Grape::DSL::Environment
         
       end
    end
    describe Environment do
      subject { EnvironmentSpec::Dummy.new }

      describe ".original_fullpath" do
        it "should return original_fullpath" do
          request = Grape::Request.new(Rack::MockRequest.env_for('/hello', method: 'GET'))
          expect(subject.original_path).to eq('/hello')
        end
      end
    end
  end
end