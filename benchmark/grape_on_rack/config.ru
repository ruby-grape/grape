# frozen_string_literal: true

require 'grape'
require 'grape-entity'
require 'grape-swagger'
require 'mime/types'
require 'ostruct'
require 'rack/cors'

Dir[File.expand_path('api/*.rb', __dir__)].each { |file| require file }
require_relative 'app/api'
require_relative 'app/acme_app'

Grape.configure do |config|
  config.eager_load_i18n = true
end

Acme::API.compile!

run Acme::App.instance
