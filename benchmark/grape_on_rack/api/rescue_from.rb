# frozen_string_literal: true

module Acme
  class RescueFrom < Grape::API
    rescue_from :all do |e|
      Rack::Response.new([e.message], 500, 'Content-type' => 'text/error')
    end
    desc 'Raises an exception.' do
      success [{ code: 500, message: 'Error: Internal Server Error' }]
    end
    get :raise do
      raise 'Unexpected error.'
    end
  end
end
