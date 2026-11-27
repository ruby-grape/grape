# frozen_string_literal: true

describe Grape::ErrorFormatter::Sse do
  let(:app) do
    Class.new(Grape::API) do
      content_type :sse, 'text/event-stream'
      format :sse

      get(:message) { error!('nope', 401) }
      get(:hash) { error!({ code: 'nope', detail: "two\nlines" }, 422) }
    end
  end

  it 'renders a message as the data of one error event' do
    get '/message'
    expect(last_response.status).to eq(401)
    expect(last_response.content_type).to eq('text/event-stream')
    expect(last_response.body).to eq(%(event: error\ndata: {"error":"nope"}\n\n))
  end

  it 'renders a Hash as the data of one error event' do
    get '/hash'
    expect(last_response.body).to eq(%(event: error\ndata: {"code":"nope","detail":"two\\nlines"}\n\n))
  end
end
