# frozen_string_literal: true

describe Grape::Validations::Validators::AtLeastOneOfValidator do
  describe '#validate!' do
    subject(:validate) { post path, params }

    describe '/' do
      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            optional :beer, :wine, :grapefruit
            at_least_one_of :beer, :wine, :grapefruit
          end
          post do
          end
        end
      end

      context 'when all restricted params are present' do
        let(:path) { '/' }
        let(:params) { { beer: true, wine: true, grapefruit: true } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when a subset of restricted params are present' do
        let(:path) { '/' }
        let(:params) { { beer: true, grapefruit: true } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when none of the restricted params is selected' do
        let(:path) { '/' }
        let(:params) { { other: true } }

        it 'returns a validation error' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'beer,wine,grapefruit' => ['are missing, at least one parameter must be provided']
          )
        end
      end

      context 'when exactly one of the restricted params is selected' do
        let(:path) { '/' }
        let(:params) { { beer: true } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end
    end

    describe '/mixed-params' do
      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            optional :beer, :wine, :grapefruit, :other
            at_least_one_of :beer, :wine, :grapefruit
          end
          post 'mixed-params' do
          end
        end
      end

      let(:path) { '/mixed-params' }
      let(:params) { { beer: true, wine: true, grapefruit: true, other: true } }

      it 'does not return a validation error' do
        validate
        expect(last_response.status).to eq 201
      end
    end

    describe '/custom-message' do
      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            optional :beer, :wine, :grapefruit
            at_least_one_of :beer, :wine, :grapefruit, message: 'you should choose something'
          end
          post '/custom-message' do
          end
        end
      end

      let(:path) { '/custom-message' }
      let(:params) { { other: true } }

      it 'returns a validation error' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'beer,wine,grapefruit' => ['you should choose something']
        )
      end
    end

    describe '/nested-hash' do
      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            requires :item, type: Hash do
              optional :beer, :wine, :grapefruit
              at_least_one_of :beer, :wine, :grapefruit, message: 'fail'
            end
          end
          post '/nested-hash' do
          end
        end
      end

      let(:path) { '/nested-hash' }

      context 'when at least one of them is present' do
        let(:params) { { item: { beer: true, wine: true } } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when none of them are present' do
        let(:params) { { item: { other: true } } }

        it 'returns a validation error with full names of the params' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'item[beer],item[wine],item[grapefruit]' => ['fail']
          )
        end
      end
    end

    describe '/nested-array' do
      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            requires :items, type: Array do
              optional :beer, :wine, :grapefruit
              at_least_one_of :beer, :wine, :grapefruit, message: 'fail'
            end
          end
          post '/nested-array' do
          end
        end
      end

      let(:path) { '/nested-array' }

      context 'when at least one of them is present' do
        let(:params) { { items: [{ beer: true, wine: true }, { grapefruit: true }] } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when none of them are present' do
        let(:params) { { items: [{ beer: true, other: true }, { other: true }] } }

        it 'returns a validation error with full names of the params' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'items[1][beer],items[1][wine],items[1][grapefruit]' => ['fail']
          )
        end
      end
    end

    describe '/deeply-nested-array' do
      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            requires :items, type: Array do
              requires :nested_items, type: Array do
                optional :beer, :wine, :grapefruit
                at_least_one_of :beer, :wine, :grapefruit, message: 'fail'
              end
            end
          end
          post '/deeply-nested-array' do
          end
        end
      end

      let(:path) { '/deeply-nested-array' }

      context 'when at least one of them is present' do
        let(:params) { { items: [{ nested_items: [{ wine: true }] }] } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when none of them are present' do
        let(:params) { { items: [{ nested_items: [{ other: true }] }] } }

        it 'returns a validation error with full names of the params' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'items[0][nested_items][0][beer],items[0][nested_items][0][wine],items[0][nested_items][0][grapefruit]' => ['fail']
          )
        end
      end
    end

    describe 'when the group sits in an optional Hash under an Array' do
      subject(:validate) { post path, params.to_json, 'CONTENT_TYPE' => 'application/json' }

      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            requires :items, type: Array do
              optional :meta, type: Hash do
                optional :beer
                optional :wine
                at_least_one_of :beer, :wine
              end
            end
          end
          post '/optional-hash-array' do
          end
        end
      end

      let(:path) { '/optional-hash-array' }

      context 'when one element sends meta and another sends it empty' do
        let(:params) { { items: [{ meta: { beer: true } }, { meta: {} }] } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when an element sends meta without any of them' do
        let(:params) { { items: [{ meta: { beer: true } }, { meta: { other: true } }] } }

        it 'returns a validation error for that element' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'items[1][meta][beer],items[1][meta][wine]' => ['are missing, at least one parameter must be provided']
          )
        end
      end
    end

    describe 'when the group sits in a nested optional Array' do
      subject(:validate) { post path, params.to_json, 'CONTENT_TYPE' => 'application/json' }

      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            requires :orders, type: Array do
              optional :items, type: Array do
                optional :a
                optional :b
                at_least_one_of :a, :b
              end
            end
          end
          post '/nested-optional-array' do
          end
        end
      end

      let(:path) { '/nested-optional-array' }
      let(:params) { { orders: [{ items: [{ a: 1 }] }, { items: [{}] }] } }

      it 'does not return a validation error for an Array whose elements are all empty' do
        validate
        expect(last_response.status).to eq 201
      end
    end

    describe 'when the group sits in a given under an optional Array' do
      subject(:validate) { post path, params.to_json, 'CONTENT_TYPE' => 'application/json' }

      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            optional :items, type: Array do
              optional :kind
              given kind: ->(v) { v != 'y' } do
                optional :beer
                optional :wine
                at_least_one_of :beer, :wine
              end
            end
          end
          post '/given-optional-array' do
          end
        end
      end

      let(:path) { '/given-optional-array' }
      let(:params) { { items: [{ kind: 'x', beer: true }, {}] } }

      it 'returns a validation error for an element sent empty' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'items[1][beer],items[1][wine]' => ['are missing, at least one parameter must be provided']
        )
      end
    end

    describe 'string group attrs under build_with :hash' do
      let(:app) do
        Class.new(Grape::API) do
          build_with :hash

          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            optional :beer
            optional :wine
            at_least_one_of 'beer', 'wine'
          end
          post do
          end
        end
      end

      let(:path) { '/' }
      let(:params) { { beer: true } }

      it 'does not return a validation error' do
        validate
        expect(last_response.status).to eq 201
      end
    end

    describe 'when the same attr is named twice in the group' do
      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            optional :beer
            optional :wine
            at_least_one_of(*%i[beer beer wine])
          end
          post do
          end
        end
      end

      let(:path) { '/' }
      let(:params) { {} }

      it 'returns a validation error with deduplicated names' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'beer,wine' => ['are missing, at least one parameter must be provided']
        )
      end
    end
  end
end
