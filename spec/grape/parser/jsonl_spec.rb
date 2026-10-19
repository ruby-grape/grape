# frozen_string_literal: true

describe Grape::Parser::Jsonl do
  let(:app) do
    Class.new(Grape::API) do
      content_type :jsonl, 'application/jsonl'
      format :jsonl

      post do
        { body: env[Grape::Env::API_REQUEST_BODY], params: params.to_h }
      end
    end
  end

  let(:content_type) { 'application/jsonl' }

  def post_lines(body)
    post '/', body, 'CONTENT_TYPE' => content_type
  end

  it 'answers each line as an element of the request body, leaving params empty' do
    post_lines %({"a":1}\n{"b":2}\n)
    expect(last_response.status).to eq(201)
    expect(JSON.parse(last_response.body)).to eq('body' => [{ 'a' => 1 }, { 'b' => 2 }], 'params' => {})
  end

  it 'reads a last line that has no newline' do
    post_lines %({"a":1}\n{"b":2})
    expect(JSON.parse(last_response.body)['body']).to eq([{ 'a' => 1 }, { 'b' => 2 }])
  end

  it 'skips blank lines and reads CRLF line ends' do
    post_lines %({"a":1}\r\n\r\n  \n{"b":2}\r\n)
    expect(JSON.parse(last_response.body)['body']).to eq([{ 'a' => 1 }, { 'b' => 2 }])
  end

  it 'keeps a line holding null or false' do
    post_lines %(null\nfalse\n)
    expect(JSON.parse(last_response.body)['body']).to eq([nil, false])
  end

  it 'answers 400 when a line is not JSON' do
    post_lines %({"a":1}\nnope\n)
    expect(last_response.status).to eq(400)
    expect(last_response.body).to include('message body does not match declared format')
  end

  context 'with a content type registered for :jsonl' do
    let(:app) do
      Class.new(Grape::API) do
        content_type :jsonl, 'application/x-ndjson'
        format :jsonl

        post { env[Grape::Env::API_REQUEST_BODY] }
      end
    end

    let(:content_type) { 'application/x-ndjson' }

    it 'parses a body of that content type' do
      post_lines %({"a":1}\n{"b":2}\n)
      expect(last_response.body).to eq(%({"a":1}\n{"b":2}\n))
    end
  end
end
