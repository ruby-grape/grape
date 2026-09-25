# frozen_string_literal: true

module Acme
  class ContentType < Grape::API
    format :json
    content_type :txt, 'text/plain'
    content_type :xml, 'application/xml'

    desc 'Returns a plain text file.'
    get 'plain_text' do
      content_type 'text/plain'
      env['api.format'] = :binary
      'A red brown fox jumped over the road.'
    end

    desc 'Returns a response in either XML or JSON format.'
    get 'mixed' do
      { data: 'A red brown fox jumped over the road.' }
    end
  end
end
