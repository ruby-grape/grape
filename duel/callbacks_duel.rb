# frozen_string_literal: true

require_relative 'duel_helper'

# Callbacks and helpers: an endpoint runs the before, validation, after
# and finally callbacks of every namespace it's in, and its block calls
# helpers, reads headers, and sets the status, headers and cookies.

module AuthHelpers
  def current_user
    @current_user ||= { id: 1, name: 'Ada', token: headers['Authorization'].to_s.delete_prefix('Bearer ') }
  end

  def authenticate!
    error!('Unauthorized', 401) unless current_user[:token] == 's3cret'
  end
end

class CallbacksAPI < Grape::API
  format :json
  helpers AuthHelpers

  helpers do
    def request_id
      headers['X-Request-Id'] || 'none'
    end

    params :pagination do
      optional :page, type: Integer, default: 1
      optional :per_page, type: Integer, default: 25
    end
  end

  before { header 'X-Request-Id', request_id }
  before { authenticate! }
  after { header 'X-Runtime', '0.001' }
  finally { @finished = true }

  namespace :admin do
    before { header 'X-Admin', 'true' }
    before_validation { @validating = true }
    after_validation { @validated = true }
    after { header 'Cache-Control', 'no-store' }

    params do
      use :pagination
    end
    get :reports do
      status 200
      header 'X-Total-Count', '3'
      cookies[:last_seen] = { value: 'reports', path: '/admin', httponly: true }
      { user: current_user[:name], page: params[:page], request_id: }
    end
  end
end

AUTHORIZED = { 'Authorization' => 'Bearer s3cret', 'X-Request-Id' => '0f8fad5b-d9cb-469f-a165-70867728950e' }.freeze

duel 'callbacks: before, validation, after and finally callbacks, with helpers' do |n|
  once { prepare(CallbacksAPI, rack_env('/admin/reports?page=2', headers: AUTHORIZED), 200, 'Ada') }
  serve(@app, @env, n)
end

duel 'callbacks: a before callback that halts with error!' do |n|
  once { prepare(CallbacksAPI, rack_env('/admin/reports', headers: { 'Authorization' => 'Bearer wrong' }), 401, 'Unauthorized') }
  serve(@app, @env, n)
end
