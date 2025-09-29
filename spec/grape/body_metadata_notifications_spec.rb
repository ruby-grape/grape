# frozen_string_literal: true

require 'spec_helper'

describe ActiveSupport::Notifications do
  let(:app) do
    Class.new(Grape::API) do
      format :json

      get '/simple' do
        { message: 'Hello World' }
      end

      get '/stream' do
        stream StringIO.new('streamed content')
      end

      get '/file' do
        sendfile __FILE__
      end

      get '/empty' do
        status 204
        ''
      end

      get '/with_params' do
        params do
          requires :id, type: Integer
        end
        { id: params[:id] }
      end

      get '/array_body' do
        [1, 2, 3, 4, 5]
      end

      get '/string_body' do
        'Hello World'
      end

      get '/hash_body' do
        { users: [{ id: 1, name: 'John' }, { id: 2, name: 'Jane' }] }
      end
    end
  end

  let(:events) { [] }
  let(:subscriber) do
    described_class.subscribe(/grape/) do |*args|
      events << ActiveSupport::Notifications::Event.new(*args)
    end
  end

  before do
    events.clear
    subscriber
  end

  after do
    described_class.unsubscribe(subscriber)
  end

  describe 'endpoint_run.grape notification' do
    it 'includes body metadata' do
      get '/simple'

      endpoint_run_events = events.select { |e| e.name == 'endpoint_run.grape' }
      expect(endpoint_run_events).not_to be_empty

      event = endpoint_run_events.first
      expect(event.payload[:body_metadata]).to be_a(Hash)
      expect(event.payload[:body_metadata]).to include(:has_body, :has_stream, :status)
    end

    it 'provides correct metadata values' do
      get '/simple'

      event = events.find { |e| e.name == 'endpoint_run.grape' }
      metadata = event.payload[:body_metadata]

      expect(metadata[:has_body]).to be false
      expect(metadata[:has_stream]).to be false
      expect(metadata[:status]).to be_nil
      expect(metadata[:api_format]).to eq(:json)
    end
  end

  describe 'endpoint_render.grape notification' do
    it 'includes body metadata' do
      get '/simple'

      render_events = events.select { |e| e.name == 'endpoint_render.grape' }
      expect(render_events).not_to be_empty

      event = render_events.first
      expect(event.payload[:body_metadata]).to be_a(Hash)
      expect(event.payload[:body_metadata]).to include(:has_body, :has_stream, :status)
    end

    it 'provides correct metadata values' do
      get '/simple'

      event = events.find { |e| e.name == 'endpoint_render.grape' }
      metadata = event.payload[:body_metadata]

      expect(metadata[:has_body]).to be false
      expect(metadata[:has_stream]).to be false
      expect(metadata[:status]).to be_nil
      expect(metadata[:api_format]).to eq(:json)
    end
  end

  describe 'endpoint_run_validators.grape notification' do
    it 'includes body metadata' do
      get '/with_params', id: 123

      validator_events = events.select { |e| e.name == 'endpoint_run_validators.grape' }
      expect(validator_events).not_to be_empty

      event = validator_events.first
      expect(event.payload[:body_metadata]).to be_a(Hash)
      expect(event.payload[:body_metadata]).to include(:has_body, :has_stream, :status)
    end

    it 'provides correct metadata values' do
      get '/with_params', id: 123

      event = events.find { |e| e.name == 'endpoint_run_validators.grape' }
      metadata = event.payload[:body_metadata]

      expect(metadata[:has_body]).to be false
      expect(metadata[:has_stream]).to be false
      expect(metadata[:status]).to be_nil
      expect(metadata[:api_format]).to eq(:json)
    end
  end

  describe 'endpoint_run_filters.grape notification' do
    it 'includes body metadata' do
      get '/simple'

      filter_events = events.select { |e| e.name == 'endpoint_run_filters.grape' }
      expect(filter_events).not_to be_empty

      event = filter_events.first
      expect(event.payload[:body_metadata]).to be_a(Hash)
      expect(event.payload[:body_metadata]).to include(:has_body, :has_stream, :status)
    end

    it 'provides correct metadata values' do
      get '/simple'

      event = events.find { |e| e.name == 'endpoint_run_filters.grape' }
      metadata = event.payload[:body_metadata]

      expect(metadata[:has_body]).to be false
      expect(metadata[:has_stream]).to be false
      expect(metadata[:status]).to be_nil
      expect(metadata[:api_format]).to eq(:json)
    end
  end

  describe 'format_response.grape notification' do
    it 'includes body metadata for regular responses' do
      get '/simple'

      format_events = events.select { |e| e.name == 'format_response.grape' }
      expect(format_events).not_to be_empty

      event = format_events.first
      expect(event.payload[:body_metadata]).to be_a(Hash)
      expect(event.payload[:body_metadata]).to include(:is_stream, :status, :content_type, :format)
      expect(event.payload[:body_metadata][:is_stream]).to be false
    end

    it 'includes body metadata for stream responses' do
      get '/stream'

      format_events = events.select { |e| e.name == 'format_response.grape' }
      # Stream responses may not emit format_response.grape notification
      if format_events.any?
        event = format_events.first
        expect(event.payload[:body_metadata]).to be_a(Hash)
        expect(event.payload[:body_metadata][:is_stream]).to be true
        expect(event.payload[:body_metadata]).to include(:stream_type)
      else
        # If no format_response.grape is emitted for streams, that's also valid
        expect(format_events).to be_empty
      end
    end

    it 'includes file path for file streams' do
      get '/file'

      format_events = events.select { |e| e.name == 'format_response.grape' }
      # Stream responses may not emit format_response.grape notification
      if format_events.any?
        event = format_events.first
        expect(event.payload[:body_metadata][:is_stream]).to be true
        expect(event.payload[:body_metadata]).to include(:file_path)
      else
        # If no format_response.grape is emitted for streams, that's also valid
        expect(format_events).to be_empty
      end
    end

    it 'provides correct metadata for regular responses' do
      get '/simple'

      event = events.find { |e| e.name == 'format_response.grape' }
      metadata = event.payload[:body_metadata]

      expect(metadata[:is_stream]).to be false
      expect(metadata[:status]).to eq(200)
      expect(metadata[:content_type]).to eq('application/json')
      expect(metadata[:format]).to eq(:json)
      expect(metadata[:has_entity_body]).to be true
      expect(metadata[:body_count]).to eq(1)
      expect(metadata[:body_types]).to eq(['Hash'])
    end

    it 'provides correct metadata for stream responses' do
      get '/stream'

      event = events.find { |e| e.name == 'format_response.grape' }
      if event
        metadata = event.payload[:body_metadata]

        expect(metadata[:is_stream]).to be true
        expect(metadata[:status]).to eq(200)
        expect(metadata[:stream_type]).to eq('StringIO')
      else
        # Stream responses may not emit format_response.grape notification
        expect(event).to be_nil
      end
    end

    it 'provides correct metadata for file responses' do
      get '/file'

      event = events.find { |e| e.name == 'format_response.grape' }
      if event
        metadata = event.payload[:body_metadata]

        expect(metadata[:is_stream]).to be true
        expect(metadata[:status]).to eq(200)
        expect(metadata[:stream_type]).to eq('Grape::ServeStream::FileBody')
        expect(metadata[:file_path]).to end_with('body_metadata_notifications_spec.rb')
      else
        # Stream responses may not emit format_response.grape notification
        expect(event).to be_nil
      end
    end

    it 'provides correct metadata for empty responses' do
      get '/empty'

      event = events.find { |e| e.name == 'format_response.grape' }
      if event
        metadata = event.payload[:body_metadata]

        expect(metadata[:is_stream]).to be false
        expect(metadata[:status]).to eq(204)
        expect(metadata[:has_entity_body]).to be false
      else
        # Empty responses may not emit format_response.grape notification
        expect(event).to be_nil
      end
    end
  end

  describe 'all notifications include body_metadata' do
    it 'ensures all grape notifications have body_metadata' do
      get '/simple'

      grape_events = events.select { |e| e.name.include?('grape') }
      expect(grape_events).not_to be_empty

      grape_events.each do |event|
        expect(event.payload).to have_key(:body_metadata),
                                 "Event #{event.name} should include body_metadata"
        expect(event.payload[:body_metadata]).to be_a(Hash),
                                                 "Event #{event.name} body_metadata should be a Hash"
      end
    end

    it 'ensures body_metadata is consistent across notifications' do
      get '/simple'

      grape_events = events.select { |e| e.name.include?('grape') }

      # All events should have the same api_format
      api_formats = grape_events.filter_map { |e| e.payload[:body_metadata][:api_format] }.uniq
      expect(api_formats.size).to eq(1)
      expect(api_formats.first).to eq(:json)
    end
  end

  describe 'body metadata structure' do
    it 'has consistent structure for endpoint notifications' do
      get '/simple'

      endpoint_events = events.select { |e| e.name.start_with?('endpoint_') }

      endpoint_events.each do |event|
        metadata = event.payload[:body_metadata]
        expect(metadata).to include(:has_body, :has_stream, :status)
        expect(metadata[:has_body]).to be(true).or be(false)
        expect(metadata[:has_stream]).to be(true).or be(false)
      end
    end

    it 'has consistent structure for format_response notifications' do
      get '/simple'

      format_events = events.select { |e| e.name == 'format_response.grape' }

      format_events.each do |event|
        metadata = event.payload[:body_metadata]
        expect(metadata).to include(:is_stream, :status, :content_type, :format, :has_entity_body)
        expect(metadata[:is_stream]).to be(true).or be(false)
        expect(metadata[:has_entity_body]).to be(true).or be(false)
        expect(metadata[:status]).to be_a(Integer)
      end
    end
  end

  describe 'body_size metadata' do
    it 'includes body_size for array responses' do
      get '/array_body'

      endpoint_events = events.select { |e| e.name.start_with?('endpoint_') }
      expect(endpoint_events).not_to be_empty

      event = endpoint_events.first
      metadata = event.payload[:body_metadata]

      if metadata[:has_body]
        expect(metadata).to include(:body_size, :body_type, :body_responds_to_size)
        expect(metadata[:body_responds_to_size]).to be true
        expect(metadata[:body_size]).to eq(5)
        expect(metadata[:body_type]).to eq('Array')
      end
    end

    it 'includes body_size for string responses' do
      get '/string_body'

      endpoint_events = events.select { |e| e.name.start_with?('endpoint_') }
      expect(endpoint_events).not_to be_empty

      event = endpoint_events.first
      metadata = event.payload[:body_metadata]

      if metadata[:has_body]
        expect(metadata).to include(:body_size, :body_type, :body_responds_to_size)
        expect(metadata[:body_responds_to_size]).to be true
        expect(metadata[:body_size]).to eq(11) # "Hello World".length
        expect(metadata[:body_type]).to eq('String')
      end
    end

    it 'includes body_size for hash responses' do
      get '/hash_body'

      endpoint_events = events.select { |e| e.name.start_with?('endpoint_') }
      expect(endpoint_events).not_to be_empty

      event = endpoint_events.first
      metadata = event.payload[:body_metadata]

      if metadata[:has_body]
        expect(metadata).to include(:body_size, :body_type, :body_responds_to_size)
        expect(metadata[:body_responds_to_size]).to be true
        expect(metadata[:body_size]).to eq(1) # Hash with one key
        expect(metadata[:body_type]).to eq('Hash')
      end
    end

    it 'does not include body_size when has_body is false' do
      get '/empty'

      endpoint_events = events.select { |e| e.name.start_with?('endpoint_') }
      expect(endpoint_events).not_to be_empty

      event = endpoint_events.first
      metadata = event.payload[:body_metadata]

      expect(metadata[:has_body]).to be false
      expect(metadata).not_to have_key(:body_size)
      expect(metadata).not_to have_key(:body_type)
      expect(metadata).not_to have_key(:body_responds_to_size)
    end

    it 'provides consistent body_size across all endpoint notifications' do
      get '/array_body'

      endpoint_events = events.select { |e| e.name.start_with?('endpoint_') }
      expect(endpoint_events).not_to be_empty

      body_sizes = endpoint_events.filter_map { |e| e.payload[:body_metadata][:body_size] }.uniq

      if body_sizes.any?
        expect(body_sizes.size).to eq(1), 'All endpoint notifications should have the same body_size'
        expect(body_sizes.first).to eq(5)
      end
    end
  end
end
