# frozen_string_literal: true

describe Grape::ErrorFormatter::Jsonl do
  let(:app) do
    Class.new(Grape::API) do
      content_type :jsonl, 'application/jsonl'
      format :jsonl

      get(:message) { error!('nope', 422) }
      get(:hash) { error!({ code: 'nope', detail: 'line' }, 422) }
    end
  end

  it 'renders a message as one JSON line' do
    get '/message'
    expect(last_response.status).to eq(422)
    expect(last_response.content_type).to eq('application/jsonl')
    expect(last_response.body).to eq(%({"error":"nope"}\n))
  end

  it 'renders a Hash as one JSON line' do
    get '/hash'
    expect(last_response.body).to eq(%({"code":"nope","detail":"line"}\n))
  end
end
