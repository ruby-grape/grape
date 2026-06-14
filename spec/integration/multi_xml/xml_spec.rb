# frozen_string_literal: true

describe Grape::Xml, if: defined?(MultiXml) do
  # Exercise the full request stack: a Grape API parses an XML body through the
  # active multi_xml backend (MultiXML on >= 0.9, the legacy MultiXml alias on
  # < 0.9). Calling parse through the deprecated MultiXml constant would raise
  # via the suite's deprecation handler (see spec/support/deprecated_warning_handlers.rb).
  let(:app) do
    Class.new(Grape::API) do
      post '/request_body' do
        params[:user]
      end
    end
  end

  it 'parses an XML request body into params' do
    env = Rack::MockRequest.env_for('/request_body', method: Rack::POST, input: '<user>Bobby T.</user>', 'CONTENT_TYPE' => 'application/xml')
    response = Rack::MockResponse[*app.call(env)]

    expect(response.status).to eq(201)
    expect(response.body).to eq('Bobby T.')
  end
end
