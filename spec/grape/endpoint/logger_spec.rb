# frozen_string_literal: true

describe Grape::Endpoint, '#logger' do
  let(:log_output) { StringIO.new }
  let(:configured_logger) { Logger.new(log_output) }

  context 'inside a route handler' do
    let(:app) do
      logger_instance = configured_logger
      Class.new(Grape::API) do
        format :txt
        logger logger_instance
        get('/') do
          logger.error('from-route')
          'ok'
        end
      end
    end

    it "returns the API's configured logger" do
      get '/'
      expect(log_output.string).to include('from-route')
    end
  end

  context 'inside a before/after/after_validation/finally filter' do
    let(:app) do
      logger_instance = configured_logger
      Class.new(Grape::API) do
        format :txt
        logger logger_instance
        before              { logger.error('from-before') }

        before_validation   { logger.error('from-before_validation') }
        after_validation    { logger.error('from-after_validation') }
        after               { logger.error('from-after') }

        finally             { logger.error('from-finally') }
        get('/') { 'ok' }
      end
    end

    it 'is reachable in every filter' do
      get '/'
      log = log_output.string
      expect(log).to include('from-before')
      expect(log).to include('from-before_validation')
      expect(log).to include('from-after_validation')
      expect(log).to include('from-after')
      expect(log).to include('from-finally')
    end
  end

  context 'inside a rescue_from block' do
    let(:app) do
      logger_instance = configured_logger
      Class.new(Grape::API) do
        format :txt
        logger logger_instance
        rescue_from :all do |e|
          logger.error("rescued: #{e.class}")
          error!('handled', 500)
        end
        get('/') { raise ArgumentError, 'boom' }
      end
    end

    it 'is reachable from the handler' do
      get '/'
      expect(log_output.string).to include('rescued: ArgumentError')
    end
  end

  context 'when a user-defined helper overrides #logger' do
    let(:app) do
      logger_instance = configured_logger
      Class.new(Grape::API) do
        format :txt
        logger logger_instance
        helpers do
          def logger
            'overridden-helper'
          end
        end
        get('/') { logger }
      end
    end

    it 'honours the user override (helpers win over endpoint method)' do
      get '/'
      expect(last_response.body).to eq('overridden-helper')
    end
  end
end
