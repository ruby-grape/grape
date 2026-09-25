# frozen_string_literal: true

require_relative 'wrap_response_decorator'

module Acme
  class WrapResponse < Grape::API
    use WrapResponseDecorator
    format :json
    namespace :decorated do
      desc 'Returns pong.'
      get :ping do
        { ping: 'pong' }
      end
    end
  end
end
