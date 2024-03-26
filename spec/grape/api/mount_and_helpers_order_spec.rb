# frozen_string_literal: true

describe Grape::API do
  describe 'rescue_from' do
    context 'when the API is mounted AFTER defining the class rescue_from handler' do
      let(:api_rescue_from) do
        Class.new(Grape::API) do
          rescue_from :all do
            error!({ type: 'all' }, 404)
          end

          get do
            { count: 1 / 0 }
          end
        end
      end

      let(:main_rescue_from_after) do
        context = self

        Class.new(Grape::API) do
          rescue_from ZeroDivisionError do
            error!({ type: 'zero' }, 500)
          end

          mount context.api_rescue_from
        end
      end

      def app
        main_rescue_from_after
      end

      it 'is rescued by the rescue_from ZeroDivisionError handler from Main class' do
        get '/'

        expect(last_response.status).to eq(500)
        expect(last_response.body).to eq({ type: 'zero' }.to_json)
      end
    end

    context 'when the API is mounted BEFORE defining the class rescue_from handler' do
      let(:api_rescue_from) do
        Class.new(Grape::API) do
          rescue_from :all do
            error!({ type: 'all' }, 404)
          end

          get do
            { count: 1 / 0 }
          end
        end
      end
      let(:main_rescue_from_before) do
        context = self

        Class.new(Grape::API) do
          mount context.api_rescue_from

          rescue_from ZeroDivisionError do
            error!({ type: 'zero' }, 500)
          end
        end
      end

      def app
        main_rescue_from_before
      end

      it 'is rescued by the rescue_from ZeroDivisionError handler from Main class' do
        get '/'

        expect(last_response.status).to eq(500)
        expect(last_response.body).to eq({ type: 'zero' }.to_json)
      end
    end
  end

  describe 'before' do
    context 'when the API is mounted AFTER defining the before helper' do
      let(:api_before_handler) do
        Class.new(Grape::API) do
          get do
            { count: @count }.to_json
          end
        end
      end
      let(:main_before_handler_after) do
        context = self

        Class.new(Grape::API) do
          before do
            @count = 1
          end

          mount context.api_before_handler
        end
      end

      def app
        main_before_handler_after
      end

      it 'is able to access the variables defined in the before helper' do
        get '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq({ count: 1 }.to_json)
      end
    end

    context 'when the API is mounted BEFORE defining the before helper' do
      let(:api_before_handler) do
        Class.new(Grape::API) do
          get do
            { count: @count }.to_json
          end
        end
      end
      let(:main_before_handler_before) do
        context = self

        Class.new(Grape::API) do
          mount context.api_before_handler

          before do
            @count = 1
          end
        end
      end

      def app
        main_before_handler_before
      end

      it 'is able to access the variables defined in the before helper' do
        get '/'

        expect(last_response.status).to eq(200)
        expect(last_response.body).to eq({ count: 1 }.to_json)
      end
    end
  end

  describe 'after' do
    context 'when the API is mounted AFTER defining the after handler' do
      let(:api_after_handler) do
        Class.new(Grape::API) do
          get do
            { count: 1 }.to_json
          end
        end
      end
      let(:main_after_handler_after) do
        context = self

        Class.new(Grape::API) do
          after do
            error!({ type: 'after' }, 500)
          end

          mount context.api_after_handler
        end
      end

      def app
        main_after_handler_after
      end

      it 'is able to access the variables defined in the after helper' do
        get '/'

        expect(last_response.status).to eq(500)
        expect(last_response.body).to eq({ type: 'after' }.to_json)
      end
    end

    context 'when the API is mounted BEFORE defining the after helper' do
      let(:api_after_handler) do
        Class.new(Grape::API) do
          get do
            { count: 1 }.to_json
          end
        end
      end
      let(:main_after_handler_before) do
        context = self

        Class.new(Grape::API) do
          mount context.api_after_handler

          after do
            error!({ type: 'after' }, 500)
          end
        end
      end

      def app
        main_after_handler_before
      end

      it 'is able to access the variables defined in the after helper' do
        get '/'

        expect(last_response.status).to eq(500)
        expect(last_response.body).to eq({ type: 'after' }.to_json)
      end
    end
  end
end
