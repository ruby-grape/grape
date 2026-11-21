# frozen_string_literal: true

require_relative 'duel_helper'

# Compiling an API, which its first request does (or a boot that compiles
# it ahead): building each endpoint's middleware stack and the router's
# unions, buckets and table of static paths. change! discards the
# compiled instance, so that the next compile! builds it again.

# 4 resources, each with the five REST routes, and params.
class CompiledAPI < Grape::API
  format :json
  prefix :api
  version 'v1', using: :path

  4.times do |i|
    resource "resource#{i}" do
      params do
        optional :page, type: Integer, default: 1
      end
      get { [] }
      params do
        requires :name, type: String
      end
      post { {} }
      route_param :id, type: Integer do
        get { {} }
        put { {} }
        delete { {} }
      end
    end
  end
end

class PostsAPI < Grape::API
  helpers { def page = params[:page] }
  before { header 'X-Posts', 'true' }

  get { [] }
  route_param :id do
    get { { id: params[:id] } }
    namespace(:comments) { get { [] } }
  end
end

class CommentsAPI < Grape::API
  get { [] }
  get(':id') { { id: params[:id] } }
end

class MountedAPI < Grape::API
  format :json
  rescue_from :all

  mount PostsAPI => '/posts'
  mount CommentsAPI => '/comments'
  namespace :admin do
    mount PostsAPI
  end
end

duel 'compile: an API of 20 routes' do
  CompiledAPI.change!
  CompiledAPI.compile!
end

duel 'compile: an API that mounts others' do
  MountedAPI.change!
  MountedAPI.compile!
end

duel 'mount: GET a route of a mounted API' do |n|
  once { prepare(MountedAPI, rack_env('/admin/42/comments'), 200) }
  serve(@app, @env, n)
end
