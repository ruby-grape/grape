require 'spec_helper'

module Grape
  module DSL
    module InsideRouteSpec
      class Dummy
        include Grape::DSL::InsideRoute
      end
    end

    describe Endpoint do
      subject { EndpointSpec::Dummy.new }

      xdescribe '#declared' do
        it 'does some thing'
      end

      xdescribe '#version' do
        it 'does some thing'
      end

      xdescribe '#error!' do
        it 'does some thing'
      end

      xdescribe '#redirect' do
        it 'does some thing'
      end

      xdescribe '#status' do
        it 'does some thing'
      end

      xdescribe '#header' do
        it 'does some thing'
      end

      xdescribe '#content_type' do
        it 'does some thing'
      end

      xdescribe '#cookies' do
        it 'does some thing'
      end

      xdescribe '#body' do
        it 'does some thing'
      end

      xdescribe '#route' do
        it 'does some thing'
      end

      xdescribe '#present' do
        it 'does some thing'
      end

    end
  end
end
