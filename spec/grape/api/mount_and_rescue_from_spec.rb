# frozen_string_literal: true

describe Grape::API do
  def app
    subject
  end

  context 'when multiple classes defines the same rescue_from' do
    class AnAPI < Grape::API
      rescue_from ZeroDivisionError do
        error!({ type: 'an-api-zero' }, 404)
      end

      get '/an-api' do
        { count: 1 / 0 }
      end
    end

    class AnotherAPI < Grape::API
      rescue_from ZeroDivisionError do
        error!({ type: 'another-api-zero' }, 322)
      end

      get '/another-api' do
        { count: 1 / 0 }
      end
    end

    class OtherMain < Grape::API
      mount AnAPI
      mount AnotherAPI
    end

    subject { OtherMain }

    it 'is rescued by the rescue_from ZeroDivisionError handler defined inside each of the classes' do
      get '/an-api'

      expect(last_response.status).to eq(404)
      expect(last_response.body).to eq({ type: 'an-api-zero' }.to_json)

      get '/another-api'

      expect(last_response.status).to eq(322)
      expect(last_response.body).to eq({ type: 'another-api-zero' }.to_json)
    end

    context 'when some class does not define a rescue_from but it was defined in a previous mounted endpoint' do
      class AnAPIWithoutDefinedRescueFrom < Grape::API
        get '/another-api-without-defined-rescue-from' do
          { count: 1 / 0 }
        end
      end

      class OtherMainWithNotDefinedRescueFrom < Grape::API
        mount AnAPI
        mount AnotherAPI
        mount AnAPIWithoutDefinedRescueFrom
      end

      subject { OtherMainWithNotDefinedRescueFrom }

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
