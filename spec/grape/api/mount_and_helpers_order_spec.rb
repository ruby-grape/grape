# frozen_string_literal: true

describe Grape::API do
  def app
    subject
  end

  describe 'rescue_from' do
    context 'when the API is mounted AFTER defining the class rescue_from handler' do
      class APIRescueFrom < Grape::API
        rescue_from :all do
          error!({ type: 'all' }, 404)
        end

        get do
          { count: 1 / 0 }
        end
      end

      class MainRescueFromAfter < Grape::API
        rescue_from ZeroDivisionError do
          error!({ type: 'zero' }, 500)
        end

        mount APIRescueFrom
      end

      subject { MainRescueFromAfter }

      it 'is rescued by the rescue_from ZeroDivisionError handler from Main class' do
        get '/'

        expect(last_response.status).to eq(500)
        expect(last_response.body).to eq({ type: 'zero' }.to_json)
      end
    end

    context 'when the API is mounted BEFORE defining the class rescue_from handler' do
      class APIRescueFrom < Grape::API
        rescue_from :all do
          error!({ type: 'all' }, 404)
        end

        get do
          { count: 1 / 0 }
        end
      end

      class MainRescueFromBefore < Grape::API
        mount APIRescueFrom

        rescue_from ZeroDivisionError do
          error!({ type: 'zero' }, 500)
        end
      end

      subject { MainRescueFromBefore }

      it 'is rescued by the rescue_from ZeroDivisionError handler from Main class' do
        get '/'

        expect(last_response.status).to eq(500)
        expect(last_response.body).to eq({ type: 'zero' }.to_json)
      end
    end
  end

  describe 'before' do
    context 'when the API is mounted AFTER defining the before helper' do
      class APIBeforeHandler < Grape::API
        get do
          { count: @count }.to_json
        end
      end

      class MainBeforeHandlerAfter < Grape::API
        before do
          @count = 1
        end

        mount APIBeforeHandler
      end

      subject { MainBeforeHandlerAfter }

      it 'is able to access the variables defined in the before helper' do
        get '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq({ count: 1 }.to_json)
      end
    end

    context 'when the API is mounted BEFORE defining the before helper' do
      class APIBeforeHandler < Grape::API
        get do
          { count: @count }.to_json
        end
      end

      class MainBeforeHandlerBefore < Grape::API
        mount APIBeforeHandler

        before do
          @count = 1
        end
      end

      subject { MainBeforeHandlerBefore }

      it 'is able to access the variables defined in the before helper' do
        get '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq({ count: 1 }.to_json)
      end
    end
  end

  describe 'after' do
    context 'when the API is mounted AFTER defining the after handler' do
      class APIAfterHandler < Grape::API
        get do
          { count: 1 }.to_json
        end
      end

      class MainAfterHandlerAfter < Grape::API
        after do
          error!({ type: 'after' }, 500)
        end

        mount APIAfterHandler
      end

      subject { MainAfterHandlerAfter }

      it 'is able to access the variables defined in the after helper' do
        get '/'

        expect(last_response.status).to eq(500)
        expect(last_response.body).to eq({ type: 'after' }.to_json)
      end
    end

    context 'when the API is mounted BEFORE defining the after helper' do
      class APIAfterHandler < Grape::API
        get do
          { count: 1 }.to_json
        end
      end

      class MainAfterHandlerBefore < Grape::API
        mount APIAfterHandler

        after do
          error!({ type: 'after' }, 500)
        end
      end

      subject { MainAfterHandlerBefore }

      it 'is able to access the variables defined in the after helper' do
        get '/'

        expect(last_response.status).to eq(500)
        expect(last_response.body).to eq({ type: 'after' }.to_json)
      end
    end
  end
end
