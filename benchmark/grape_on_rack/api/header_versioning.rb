# frozen_string_literal: true

module Acme
  class HeaderVersioning < Grape::API
    version 'v1', using: :header, vendor: 'acme', strict: true

    format :json
    desc 'Returns acme.'
    get do
      { header: 'acme' }
    end
  end
end
