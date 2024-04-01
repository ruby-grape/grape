# frozen_string_literal: true

describe Grape::API do
  context 'when multiple classes defines the same rescue_from' do
    let(:an_api) do
      Class.new(Grape::API) do
        rescue_from ZeroDivisionError do
          error!({ type: 'an-api-zero' }, 404)
        end

        get '/an-api' do
          { count: 1 / 0 }
        end
      end
    end
    let(:another_api) do
      Class.new(Grape::API) do
        rescue_from ZeroDivisionError do
          error!({ type: 'another-api-zero' }, 322)
        end

        get '/another-api' do
          { count: 1 / 0 }
        end
      end
    end
    let(:other_main) do
      context = self

      Class.new(Grape::API) do
        mount context.an_api
        mount context.another_api
      end
    end

    def app
      other_main
    end

    it 'is rescued by the rescue_from ZeroDivisionError handler defined inside each of the classes' do
      get '/an-api'

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq({ type: 'an-api-zero' }.to_json)

      get '/another-api'

      expect(last_response.status).to eq(322)
      expect(last_response.body).to eq({ type: 'another-api-zero' }.to_json)
    end

    context 'when some class does not define a rescue_from but it was defined in a previous mounted endpoint' do
      let(:an_api_without_defined_rescue_from) do
        Class.new(Grape::API) do
          get '/another-api-without-defined-rescue-from' do
            { count: 1 / 0 }
          end
        end
      end
      let(:other_main_with_not_defined_rescue_from) do
        context = self

        Class.new(Grape::API) do
          mount context.an_api
          mount context.another_api
          mount context.an_api_without_defined_rescue_from
        end
      end

      def app
        other_main_with_not_defined_rescue_from
      end

      it 'is not rescued by any of the previous defined rescue_from ZeroDivisionError handlers' do
        get '/an-api'

        expect(last_response.status).to eq(404)
        expect(last_response.body).to eq({ type: 'an-api-zero' }.to_json)

        get '/another-api'

        expect(last_response.status).to eq(322)
        expect(last_response.body).to eq({ type: 'another-api-zero' }.to_json)

        expect do
          get '/another-api-without-defined-rescue-from'
        end.to raise_error(ZeroDivisionError)
      end
    end
  end
end
