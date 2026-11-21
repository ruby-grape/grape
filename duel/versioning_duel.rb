# frozen_string_literal: true

require_relative 'duel_helper'

# Versioning: the versioner middleware takes the version from the path,
# the Accept header, a header of its own or a param, and the router picks
# the version's routes, cascading from one version to the next.

def versioned_api(using, **options)
  Class.new(Grape::API) do
    format :json

    version('v2', using:, **options) do
      get('users/:id') { { version: 'v2', id: params[:id] } }
      get('users') { [] }
    end
    version('v1', using:, **options) do
      get('users/:id') { { version: 'v1', id: params[:id] } }
      get('users') { [] }
    end
  end
end

PathVersionedAPI = versioned_api(:path)
HeaderVersionedAPI = versioned_api(:header, vendor: 'acme', strict: true)
AcceptVersionHeaderAPI = versioned_api(:accept_version_header)
ParamVersionedAPI = versioned_api(:param, parameter: 'api_version')

duel 'versioning: a version in the path' do |n|
  once { prepare(PathVersionedAPI, rack_env('/v1/users/42'), 200, 'v1') }
  serve(@app, @env, n)
end

duel 'versioning: a vendor media type in the Accept header' do |n|
  once { prepare(HeaderVersionedAPI, rack_env('/users/42', headers: { 'Accept' => 'application/vnd.acme-v2+json' }), 200, 'v2') }
  serve(@app, @env, n)
end

# The v2 route matches the path first, and cascades when the versioner
# finds the request is for v1.
duel 'versioning: an Accept header cascading past a newer version' do |n|
  once { prepare(HeaderVersionedAPI, rack_env('/users/42', headers: { 'Accept' => 'application/vnd.acme-v1+json' }), 200, 'v1') }
  serve(@app, @env, n)
end

duel 'versioning: the Accept-Version header' do |n|
  once { prepare(AcceptVersionHeaderAPI, rack_env('/users/42', headers: { 'Accept-Version' => 'v1' }), 200, 'v1') }
  serve(@app, @env, n)
end

duel 'versioning: a version param' do |n|
  once { prepare(ParamVersionedAPI, rack_env('/users/42?api_version=v1'), 200, 'v1') }
  serve(@app, @env, n)
end
