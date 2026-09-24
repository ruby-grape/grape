# frozen_string_literal: true

module Acme
  class API < Grape::API
    prefix 'api'
    format :json
    mount ::Acme::Ping
    mount ::Acme::RescueFrom
    mount ::Acme::PathVersioning
    mount ::Acme::HeaderVersioning
    mount ::Acme::PostPut
    mount ::Acme::WrapResponse
    mount ::Acme::PostJson
    mount ::Acme::GetJson
    mount ::Acme::ContentType
    mount ::Acme::UploadFile
    mount ::Acme::Entities::API
    mount ::Acme::Headers
    mount ::Acme::StreamData
    add_swagger_documentation api_version: 'v1'
  end
end
