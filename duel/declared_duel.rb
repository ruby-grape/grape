# frozen_string_literal: true

require_relative 'duel_helper'

# declared(params), which endpoints call to take only the params they
# declared, walks the declarations against what the request sent.

class DeclaredAPI < Grape::API
  format :json

  params do
    requires :name, type: String
    optional :email, type: String
    optional :bio, type: String
    optional :role, type: String, values: %w[admin member guest], default: 'member'
    optional :settings, type: Hash do
      optional :theme, type: String
      optional :locale, type: String
      optional :notifications, type: Hash do
        optional :email, type: Grape::API::Boolean
        optional :push, type: Grape::API::Boolean
      end
    end
    optional :links, type: Array do
      requires :rel, type: String
      requires :href, type: String
      optional :title, type: String, as: :label
    end
  end
  route_param :account_id, type: Integer do
    post('profiles') { declared(params) }
    put('profiles') { declared(params, include_missing: false) }
    patch('profiles') { declared(params, stringify: true) }
  end
end

def profile_json
  {
    name: 'Katherine Johnson',
    email: 'katherine@example.com',
    unknown: 'dropped',
    settings: { theme: 'dark', notifications: { email: true } },
    links: Array.new(10) { |i| { rel: "rel#{i}", href: "https://example.com/#{i}", title: "Link #{i}", extra: i } }
  }
end

duel 'declared: all declared params, with missing ones as nil' do |n|
  once { prepare(DeclaredAPI, rack_env('/7/profiles', method: Rack::POST, json: profile_json), 201, '"bio":null') }
  serve(@app, @env, n)
end

duel 'declared: only the params sent' do |n|
  once { prepare(DeclaredAPI, rack_env('/7/profiles', method: Rack::PUT, json: profile_json), 200, 'Katherine') }
  serve(@app, @env, n)
end

duel 'declared: with string keys' do |n|
  once { prepare(DeclaredAPI, rack_env('/7/profiles', method: Rack::PATCH, json: profile_json), 200, '"label":"Link 9"') }
  serve(@app, @env, n)
end
