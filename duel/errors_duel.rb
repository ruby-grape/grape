# frozen_string_literal: true

require_relative 'duel_helper'

# Errors: error! throws to the error middleware, which renders the
# message in the request's format, and a raised exception is rescued by
# the rescue_from handler registered for its class.

class RecordNotFound < StandardError; end
class RecordInvalid < StandardError; end

class ErrorsAPI < Grape::API
  format :json

  rescue_from RecordNotFound do |e|
    error!({ error: 'not_found', message: e.message }, 404)
  end
  rescue_from RecordInvalid, ArgumentError do |e|
    error!({ error: 'invalid', message: e.message }, 422, 'X-Error' => 'invalid')
  end
  rescue_from :all do |_e|
    error!({ error: 'internal' }, 500)
  end

  get('forbidden') { error!('Forbidden', 403) }
  get('conflict') { error!({ error: 'conflict', id: 42, detail: 'The record changed since it was read.' }, 409, 'Retry-After' => '5') }
  get('missing') { raise RecordNotFound, 'no post with id 42' }
  get('invalid') { raise ArgumentError, 'invalid date' }
  get('broken') { raise TypeError, "nil can't be coerced into Integer" }
end

# Without a handler of its own, rescue_from :all answers with the
# default 500.
class DefaultErrorsAPI < Grape::API
  format :json
  rescue_from :all

  get('broken') { raise 'boom' }
end

duel 'errors: error! with a message' do |n|
  once { prepare(ErrorsAPI, rack_env('/forbidden'), 403, 'Forbidden') }
  serve(@app, @env, n)
end

duel 'errors: error! with a hash and headers' do |n|
  once { prepare(ErrorsAPI, rack_env('/conflict'), 409, 'conflict') }
  serve(@app, @env, n)
end

duel 'errors: rescue_from a class with a handler' do |n|
  once { prepare(ErrorsAPI, rack_env('/missing'), 404, 'not_found') }
  serve(@app, @env, n)
end

duel 'errors: rescue_from :all with a handler' do |n|
  once { prepare(ErrorsAPI, rack_env('/broken'), 500, 'internal') }
  serve(@app, @env, n)
end

duel 'errors: rescue_from :all with the default handler' do |n|
  once { prepare(DefaultErrorsAPI, rack_env('/broken'), 500, 'boom') }
  serve(@app, @env, n)
end
