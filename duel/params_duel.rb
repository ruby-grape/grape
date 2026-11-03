# frozen_string_literal: true

require_relative 'duel_helper'

# Declared params: each request's are coerced to their types and checked
# by the validators that `requires` and `optional` declared, from the
# query string, a form, or a JSON body.

# A custom validator, as the README shows them: `slug: true`.
class Slug < Grape::Validations::Validators::Base
  def validate_param!(attr_name, params)
    return if params[attr_name].to_s.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)

    validation_error!(attr_name, 'must be a slug')
  end
end

class ParamsAPI < Grape::API
  format :json

  params do
    requires :id, type: Integer
  end
  get('items/:id') { { id: params[:id] } }

  params do
    requires :q, type: String, allow_blank: false
    optional :page, type: Integer, default: 1, values: 1..1000
    optional :per_page, type: Integer, default: 25, values: [10, 25, 50, 100]
    optional :sort, type: Symbol, values: %i[name created_at updated_at], default: :created_at
    optional :order, type: String, values: %w[asc desc], default: 'desc'
    optional :since, type: Date
    optional :min_price, type: Float
    optional :in_stock, type: Grape::API::Boolean
    optional :tags, type: [String]
    optional :ids, type: Array[Integer], coerce_with: ->(value) { value.split(',').map(&:to_i) }
  end
  get('search') { { q: params[:q], page: params[:page], ids: params[:ids] } }

  params do
    requires :name, type: String, length: { min: 2, max: 64 }
    requires :email, type: String, regexp: /\A[^@\s]+@[^@\s]+\z/
    requires :slug, type: String, slug: true
    optional :age, type: Integer, values: 13..130
    optional :phone, type: String
    optional :website, type: String
    mutually_exclusive :phone, :website
  end
  post('users') { { name: params[:name] } }

  params do
    requires :order, type: Hash do
      requires :customer, type: Hash do
        requires :name, type: String
        requires :email, type: String
        optional :address, type: Hash do
          requires :street, type: String
          requires :city, type: String
          requires :postal_code, type: String
          optional :country, type: String, default: 'US'
        end
      end
      requires :items, type: Array, allow_blank: false do
        requires :sku, type: String
        requires :quantity, type: Integer, values: 1..100
        requires :price, type: BigDecimal
        optional :options, type: Array[String]
        optional :gift, type: Grape::API::Boolean, default: false
      end
      optional :coupon, type: String
      optional :notes, type: String
      at_least_one_of :coupon, :notes
    end
  end
  post('orders') { { items: params[:order][:items].size } }
end

# An order of 20 items, from a store's checkout, sent as JSON.
def order_json
  {
    order: {
      customer: {
        name: 'Ada Lovelace',
        email: 'ada@example.com',
        address: { street: '12 St James Square', city: 'London', postal_code: 'SW1Y 4JH' }
      },
      items: Array.new(20) do |i|
        { sku: "SKU-#{1000 + i}", quantity: (i % 5) + 1, price: format('%.2f', 9.99 + i), options: %w[blue large], gift: i.even? }
      end,
      notes: 'Please leave it at the door.'
    }
  }
end

SEARCH = '/search?q=ruby+books&page=3&per_page=50&sort=name&order=asc&since=2026-01-15' \
         '&min_price=12.5&in_stock=true&tags[]=fiction&tags[]=classic&ids=1,2,3,5,8,13'

USER = { name: 'Grace Hopper', email: 'grace@example.com', slug: 'grace-hopper', age: 85, website: 'https://example.com' }.freeze

duel 'params: coerce a path param to an Integer' do |n|
  once { prepare(ParamsAPI, rack_env('/items/42'), 200, '42') }
  serve(@app, @env, n)
end

duel 'params: coerce and validate a query string of 10 params' do |n|
  once { prepare(ParamsAPI, rack_env(SEARCH), 200, '13') }
  serve(@app, @env, n)
end

duel 'params: fill in defaults for missing optional params' do |n|
  once { prepare(ParamsAPI, rack_env('/search?q=ruby'), 200, '"page":1') }
  serve(@app, @env, n)
end

duel 'params: validate a JSON body with a custom validator' do |n|
  once { prepare(ParamsAPI, rack_env('/users', method: Rack::POST, json: USER), 201, 'Grace') }
  serve(@app, @env, n)
end

duel 'params: validate a form body' do |n|
  once do
    form = URI.encode_www_form(USER)
    env = Rack::MockRequest.env_for('/users', method: Rack::POST, input: form, 'CONTENT_TYPE' => 'application/x-www-form-urlencoded')
    prepare(ParamsAPI, env.freeze, 201, 'Grace')
  end
  serve(@app, @env, n)
end

duel 'params: validate a nested JSON body of 20 items' do |n|
  once { prepare(ParamsAPI, rack_env('/orders', method: Rack::POST, json: order_json), 201, '20') }
  serve(@app, @env, n)
end

duel 'params: reject invalid params with 400' do |n|
  once do
    invalid = USER.merge(email: 'not an email', slug: 'Not A Slug', age: 7, phone: '555-0100')
    prepare(ParamsAPI, rack_env('/users', method: Rack::POST, json: invalid), 400, 'must be a slug')
  end
  serve(@app, @env, n)
end
