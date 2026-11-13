# frozen_string_literal: true

require_relative 'duel_helper'

# Finding the route for a request: the router answers a path that a route
# spells out in full from a table, narrows the routes with a parameter by
# a path segment, and otherwise matches the union of their patterns.

class HelloAPI < Grape::API
  prefix :api
  version 'v1', using: :path
  format :json

  get('/hello') { { hello: 'world' } }
  get('/hello/:id') { { hello: params[:id] } }
end

# An app's worth of resources: 40 of them, each with the five REST routes,
# some nested under the resource before them, so 200 routes.
class ResourcesAPI < Grape::API
  prefix :api
  version 'v1', using: :path
  format :json

  40.times do |i|
    resource "resource#{i}" do
      get { [] }
      post { {} }
      route_param :id do
        get { { id: params[:id] } }
        put { { id: params[:id] } }
        delete { { id: params[:id] } }
      end
    end
  end
end

# Nested namespaces and route parameters, with requirements.
class NestedAPI < Grape::API
  prefix :api
  format :json

  namespace :orgs do
    route_param :org_id, requirements: /[a-z0-9-]+/ do
      namespace :projects do
        get { [] }
        route_param :project_id, type: Integer, requirements: /\d+/ do
          get { { project: params[:project_id] } }
          namespace :tasks do
            get { [] }
            get ':id', requirements: { id: /\d+/ } do
              { org: params[:org_id], project: params[:project_id], task: params[:id] }
            end
          end
        end
      end
    end
  end
  get 'files/*path' do
    { path: params[:path] }
  end
end

duel 'routing: GET a static route' do |n|
  once { prepare(HelloAPI, rack_env('/api/v1/hello'), 200, 'world') }
  serve(@app, @env, n)
end

duel 'routing: GET a route with a path param' do |n|
  once { prepare(HelloAPI, rack_env('/api/v1/hello/42'), 200, '42') }
  serve(@app, @env, n)
end

duel 'routing: GET the last static route of 200' do |n|
  once { prepare(ResourcesAPI, rack_env('/api/v1/resource39'), 200) }
  serve(@app, @env, n)
end

duel 'routing: GET the last param route of 200' do |n|
  once { prepare(ResourcesAPI, rack_env('/api/v1/resource39/42'), 200, '42') }
  serve(@app, @env, n)
end

duel 'routing: 404 among 200 routes' do |n|
  once { prepare(ResourcesAPI, rack_env('/api/v1/nothing/here'), 404) }
  serve(@app, @env, n)
end

duel 'routing: 405 for a method a path does not answer' do |n|
  once { prepare(ResourcesAPI, rack_env('/api/v1/resource39', method: Rack::PATCH), 405) }
  serve(@app, @env, n)
end

duel 'routing: GET three levels of nested namespaces with requirements' do |n|
  once { prepare(NestedAPI, rack_env('/api/orgs/acme-co/projects/12/tasks/345'), 200, '345') }
  serve(@app, @env, n)
end

duel 'routing: GET a wildcard route' do |n|
  once { prepare(NestedAPI, rack_env('/api/files/docs/2026/report.pdf'), 200, 'report') }
  serve(@app, @env, n)
end
