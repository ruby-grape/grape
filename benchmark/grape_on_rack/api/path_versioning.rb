# frozen_string_literal: true

module Acme
  class PathVersioning < Grape::API
    version 'vendor', using: :path, vendor: 'acme'

    format :json

    desc 'Returns acme.'
    get do
      { path: 'acme' }
    end
  end
end
