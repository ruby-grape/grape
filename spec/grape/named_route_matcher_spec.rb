require 'spec_helper'

describe Grape::NamedRouteMatcher do
  include described_class

  let(:api) { Spec::Support::RouteMatcherHelpers.api }

  let(:routes) do
    api.routes
  end

  let(:ping_route) do
    routes.detect do |route|
      route.route_path =~ /ping/
    end
  end

  let(:index_route) do
    routes.detect do |route|
      route.route_namespace =~ /cats$/
    end
  end

  let(:show_route) do
    routes.detect do |route|
      route.route_namespace =~ /cats\/:id/
    end
  end

  describe '#route_match?' do
    context 'when route responds to a method name' do
      let(:route) { ping_route }
      let(:method_name) { :api_v1_ping_path }
      let(:segments) { {} }

      context 'when segments is not a hash' do
        it 'raises an ArgumentError' do
          expect do
            route_match?(route, method_name, 1234)
          end.to raise_error(ArgumentError)
        end
      end

      it 'returns true' do
        is_match = route_match?(route, method_name, segments)
        expect(is_match).to eq(true)
      end

      context 'when requested segments contains expected options' do
        let(:segments) { { 'format' => 'xml' } }

        it 'returns true' do
          is_match = route_match?(route, method_name, segments)
          expect(is_match).to eq(true)
        end

        context 'when no dynamic segments are requested' do
          context 'when the route requires dynamic segments' do
            let(:route) { show_route }
            let(:method_name) { :ap1_v1_cats_path }

            it 'returns false' do
              is_match = route_match?(route, method_name, segments)
              expect(is_match).to eq(false)
            end
          end

          context 'when the route does not require dynamic segments' do
            it 'returns true' do
              is_match = route_match?(route, method_name, segments)
              expect(is_match).to eq(true)
            end
          end
        end

        context 'when route requires the requested segments' do
          let(:route) { show_route }
          let(:method_name) { :api_v1_cats_path }
          let(:segments) { { id: 1 } }

          it 'returns true' do
            is_match = route_match?(route, method_name, segments)
            expect(is_match).to eq(true)
          end
        end

        context 'when route does not require the requested segments' do
          let(:segments) { { some_option: 'some value' } }

          it 'returns false' do
            is_match = route_match?(route, method_name, segments)
            expect(is_match).to eq(false)
          end
        end
      end

      context 'when segments contains unexpected options' do
        let(:segments) { { some_option: 'some value' } }

        it 'returns false' do
          is_match = route_match?(route, method_name, segments)
          expect(is_match).to eq(false)
        end
      end
    end

    context 'when route does not respond to a method name' do
      let(:method_name) { :some_other_path }
      let(:route) { ping_route }
      let(:segments) { {} }

      it 'returns false' do
        is_match = route_match?(route, method_name, segments)
        expect(is_match).to eq(false)
      end
    end
  end

  describe '#method_missing' do
    context 'when method name matches a Grape::Route path helper name' do
      it 'returns the path for that route object' do
        api

        path = api_v1_ping_path
        expect(path).to eq('/api/v1/ping')
      end

      context 'when argument to the helper is not a hash' do
        it 'raises an ArgumentError' do
          api

          expect do
            api_v1_ping_path(1234)
          end.to raise_error(ArgumentError)
        end
      end
    end

    context 'when method name does not match a Grape::Route path helper name' do
      it 'raises a NameError' do
        api

        expect do
          some_method_name
        end.to raise_error(NameError)
      end
    end
  end

  context 'when Grape::Route objects share the same helper name' do
    context 'when helpers require different segments to generate their path' do
      it 'uses arguments to infer which route to use' do
        api

        show_path = api_v1_cats_path('id' => 1)
        expect(show_path).to eq('/api/v1/cats/1')

        index_path = api_v1_cats_path
        expect(index_path).to eq('/api/v1/cats')
      end
    end
  end
end
