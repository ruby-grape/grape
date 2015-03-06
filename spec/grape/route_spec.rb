require 'spec_helper'

describe Grape::Route do
  let(:api) { Spec::Support::RouteMatcherHelpers.api }

  let(:routes) do
    api.routes
  end

  let(:index_route) do
    routes.detect { |route| route.route_namespace == '/cats' }
  end

  let(:show_route) do
    routes.detect { |route| route.route_namespace == '/cats/:id' }
  end

  let(:catch_all_route) do
    routes.detect { |route| route.route_path =~ /\*/ }
  end

  describe '#helper_names' do
    context 'when an API has multiple versions' do
      let(:api_versions) { %w(beta alpha v1) }

      before do
        api.version api_versions
      end

      it "returns the route's helper name for each version" do
        helper_names = show_route.helper_names
        expect(helper_names.size).to eq(api_versions.size)
      end
    end

    context 'when an API has one version' do
      it "returns the route's helper name for that version" do
        helper_name = show_route.helper_names.first
        expect(helper_name).to eq('api_v1_cats_path')
      end
    end
  end

  describe '#helper_arguments' do
    context 'when no user input is needed to generate the correct path' do
      it 'returns an empty array' do
        expect(index_route.helper_arguments).to eq([])
      end
    end

    context 'when user input is needed to generate the correct path' do
      it 'returns an array of required segments' do
        expect(show_route.helper_arguments).to eq(['id'])
      end
    end
  end

  describe '#path_segments_with_values' do
    context 'when path has dynamic segments' do
      it 'replaces segments with corresponding values found in @options' do
        opts = { id: 1 }
        result = show_route.path_segments_with_values(opts)
        expect(result).to include(1)
      end

      context 'when options contains string keys' do
        it 'replaces segments with corresponding values found in the options' do
          opts = { 'id' => 1 }
          result = show_route.path_segments_with_values(opts)
          expect(result).to include(1)
        end
      end
    end
  end

  describe '#path_helper_name' do
    it "returns the name of a route's helper method" do
      expect(index_route.path_helper_name).to eq('api_v1_cats_path')
    end

    context 'when the path is the root path' do
      let(:api_with_root) do
        Class.new(Grape::API) do
          get '/' do
          end
        end
      end

      let(:root_route) do
        api_with_root.routes.first
      end

      it 'returns "root_path"' do
        result = root_route.path_helper_name
        expect(result).to eq('root_path')
      end
    end

    context 'when the path is a catch-all path' do
      it 'returns a name without the glob star' do
        result = catch_all_route.path_helper_name
        expect(result).to eq('api_v1_path_path')
      end
    end
  end

  describe '#segment_to_value' do
    context 'when segment is dynamic' do
      it 'returns the value the segment corresponds to' do
        result = index_route.segment_to_value(':version')
        expect(result).to eq('v1')
      end

      context 'when segment is found in options' do
        it 'returns the value found in options' do
          options = { id: 1 }
          result = show_route.segment_to_value(':id', options)
          expect(result).to eq(1)
        end
      end
    end

    context 'when segment is static' do
      it 'returns the segment' do
        result = index_route.segment_to_value('api')
        expect(result).to eq('api')
      end
    end
  end

  describe 'path helper method' do
    context 'when helper does not require arguments' do
      it 'returns the correct path' do
        path = index_route.api_v1_cats_path
        expect(path).to eq('/api/v1/cats')
      end
    end

    context 'when arguments are needed required to construct the right path' do
      context 'when not missing arguments' do
        it 'returns the correct path' do
          path = show_route.api_v1_cats_path(id: 1)
          expect(path).to eq('/api/v1/cats/1')
        end
      end
    end

    context "when a route's API has multiple versions" do
      before(:each) do
        api.version %w(v1 v2)
      end

      it 'returns a path for each version' do
        expect(index_route.api_v1_cats_path).to eq('/api/v1/cats')
        expect(index_route.api_v2_cats_path).to eq('/api/v2/cats')
      end
    end

    context 'when a format is given' do
      it 'returns the path with a correct extension' do
        path = show_route.api_v1_cats_path(id: 1, format: 'xml')
        expect(path).to eq('/api/v1/cats/1.xml')
      end
    end
  end
end
