# frozen_string_literal: true

describe Grape::Validations::Validators::ExactlyOneOfValidator do
  describe '#validate!' do
    subject(:validate) { post path, params }

    describe '/' do
      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            optional :beer
            optional :wine
            optional :grapefruit
            exactly_one_of :beer, :wine, :grapefruit
          end
          post do
          end
        end
      end

      context 'when all params are present' do
        let(:path) { '/' }
        let(:params) { { beer: true, wine: true, grapefruit: true } }

        it 'returns a validation error' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'beer,wine,grapefruit' => ['are mutually exclusive']
          )
        end
      end

      context 'when a subset of params are present' do
        let(:path) { '/' }
        let(:params) { { beer: true, grapefruit: true } }

        it 'returns a validation error' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'beer,grapefruit' => ['are mutually exclusive']
          )
        end
      end

      context 'when exacly one param is present' do
        let(:path) { '/' }
        let(:params) { { beer: true, somethingelse: true } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when none of the params are present' do
        let(:path) { '/' }
        let(:params) { { somethingelse: true } }

        it 'returns a validation error' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'beer,wine,grapefruit' => ['are missing, exactly one parameter must be provided']
          )
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
            optional :beer
            optional :wine
            optional :grapefruit
            optional :other
            exactly_one_of :beer, :wine, :grapefruit
          end
          post 'mixed-params' do
          end
        end
      end

      let(:path) { '/mixed-params' }
      let(:params) { { beer: true, wine: true, grapefruit: true, other: true } }

      it 'returns a validation error' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'beer,wine,grapefruit' => ['are mutually exclusive']
        )
      end
    end

    describe '/custom-message' do
      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            optional :beer
            optional :wine
            optional :grapefruit
            exactly_one_of :beer, :wine, :grapefruit, message: 'you should choose one'
          end
          post '/custom-message' do
          end
        end
      end

      let(:path) { '/custom-message' }
      let(:params) { { beer: true, wine: true } }

      it 'returns a validation error' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'beer,wine' => ['you should choose one']
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
              optional :beer
              optional :wine
              optional :grapefruit
              exactly_one_of :beer, :wine, :grapefruit
            end
          end
          post '/nested-hash' do
          end
        end
      end

      let(:path) { '/nested-hash' }
      let(:params) { { item: { beer: true, wine: true } } }

      it 'returns a validation error with full names of the params' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'item[beer],item[wine]' => ['are mutually exclusive']
        )
      end
    end

    describe '/nested-optional-hash' do
      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            optional :item, type: Hash do
              optional :beer
              optional :wine
              optional :grapefruit
              exactly_one_of :beer, :wine, :grapefruit
            end
          end
          post '/nested-optional-hash' do
          end
        end
      end

      let(:path) { '/nested-optional-hash' }

      context 'when params are passed' do
        let(:params) { { item: { beer: true, wine: true } } }

        it 'returns a validation error with full names of the params' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'item[beer],item[wine]' => ['are mutually exclusive']
          )
        end
      end

      context 'when params are empty' do
        let(:params) { { other: true } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
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
              optional :beer
              optional :wine
              optional :grapefruit
              exactly_one_of :beer, :wine, :grapefruit
            end
          end
          post '/nested-array' do
          end
        end
      end

      let(:path) { '/nested-array' }
      let(:params) { { items: [{ beer: true, wine: true }, { wine: true, grapefruit: true }] } }

      it 'returns a validation error with full names of the params' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'items[0][beer],items[0][wine]' => [
            'are mutually exclusive'
          ],
          'items[1][wine],items[1][grapefruit]' => [
            'are mutually exclusive'
          ]
        )
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
                optional :beer, :wine, :grapefruit, type: Grape::API::Boolean
                exactly_one_of :beer, :wine, :grapefruit
              end
            end
          end
          post '/deeply-nested-array' do
          end
        end
      end

      let(:path) { '/deeply-nested-array' }
      let(:params) { { items: [{ nested_items: [{ beer: true, wine: true }] }] } }

      it 'returns a validation error with full names of the params' do
        validate
        expect(last_response.status).to eq 400
        expect(JSON.parse(last_response.body)).to eq(
          'items[0][nested_items][0][beer],items[0][nested_items][0][wine]' => [
            'are mutually exclusive'
          ]
        )
      end
    end

    describe 'when the group sits in a given under an Array' do
      let(:app) do
        Class.new(Grape::API) do
          rescue_from Grape::Exceptions::ValidationErrors do |e|
            error!(e.errors.transform_keys! { |key| key.join(',') }, 400)
          end

          params do
            requires :items, type: Array do
              optional :kind
              given kind: ->(v) { v == 'x' } do
                optional :beer
                optional :wine
                exactly_one_of :beer, :wine
              end
            end
          end
          post '/given-array' do
          end
        end
      end

      let(:path) { '/given-array' }

      context 'when a later element does not meet the dependency' do
        let(:params) { { items: [{ kind: 'x', beer: true }, { kind: 'y' }] } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when an element meets the dependency and violates the rule' do
        let(:params) { { items: [{ kind: 'x', beer: true, wine: true }, { kind: 'y' }] } }

        it 'returns a validation error for that element only' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'items[0][beer],items[0][wine]' => ['are mutually exclusive']
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
                exactly_one_of :beer, :wine
              end
            end
          end
          post '/optional-hash-array' do
          end
        end
      end

      let(:path) { '/optional-hash-array' }

      context 'when meta is empty' do
        let(:params) { { items: [{ meta: {} }] } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when meta is omitted' do
        let(:params) { { items: [{}] } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when one element sends meta and another sends it empty' do
        let(:params) { { items: [{ meta: { beer: true } }, { meta: {} }] } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
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
            exactly_one_of(*%i[beer beer wine])
          end
          post do
          end
        end
      end

      let(:path) { '/' }

      context 'when exactly one unique attr is sent' do
        let(:params) { { beer: true } }

        it 'does not return a validation error' do
          validate
          expect(last_response.status).to eq 201
        end
      end

      context 'when none of the attrs are sent' do
        let(:params) { {} }

        it 'returns a validation error with deduplicated names' do
          validate
          expect(last_response.status).to eq 400
          expect(JSON.parse(last_response.body)).to eq(
            'beer,wine' => ['are missing, exactly one parameter must be provided']
          )
        end
      end
    end
  end
end
