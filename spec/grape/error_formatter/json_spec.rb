# frozen_string_literal: true

describe Grape::ErrorFormatter::Json do
  let(:app) do
    Class.new(Grape::API) do
      format :json
      get('/utf8') { error!('café', 400) }
      get('/binary') { error!("caf\xC3\xA9".b, 400) }
      get('/malformed') { error!("caf\xC3", 400) }
    end
  end

  # A String message goes out as UTF-8 whatever it arrived as: one that already
  # is valid UTF-8 as it is, anything else converted, with what does not
  # convert replaced rather than failing the response.
  it 'renders a UTF-8 message as it is' do
    get '/utf8'
    expect(JSON.parse(last_response.body)).to eq('error' => 'café')
  end

  it 'converts a binary message, replacing the bytes it cannot map' do
    get '/binary'
    expect(JSON.parse(last_response.body)).to eq('error' => 'caf��')
  end

  it 'replaces the invalid bytes of a malformed UTF-8 message' do
    get '/malformed'
    expect(JSON.parse(last_response.body)).to eq('error' => 'caf�')
  end
end
