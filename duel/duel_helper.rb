# frozen_string_literal: true

require 'json'
require 'stringio'

# Requests go to an API through its Rack interface, in memory, as a
# server would hand them over: no server, no sockets.

# The env of a request to +path+, as Rack builds it. +headers+ are HTTP
# headers by name, and +json+ is sent as a JSON body.
def rack_env(path, method: Rack::GET, headers: {}, json: nil)
  options = { method: }
  if json
    options[:input] = JSON.generate(json)
    options['CONTENT_TYPE'] = 'application/json'
  end
  env = Rack::MockRequest.env_for(path, options)
  headers.each { |name, value| env["HTTP_#{name.upcase.tr('-', '_')}"] = value }
  env.freeze
end

# A copy of +env+ with an input of its own. Grape and Rack write what
# they parse into the env, and read the body from rack.input, so each
# request needs a fresh one, as a server gives it.
def fresh_env(env)
  input = env[Rack::RACK_INPUT]
  return env.dup unless input

  env.merge(Rack::RACK_INPUT => StringIO.new(input.string))
end

# Calls +app+ with +env+ and reads the whole body, as a server does.
# Returns the status and the body.
def respond(app, env)
  status, _headers, body = app.call(env)
  text = +''
  body.each { |chunk| text << chunk }
  body.close if body.respond_to?(:close)
  [status, text]
end

# Answers +count+ requests for +env+, each with an env of its own, made
# outside the measured time.
def serve(app, env, count)
  envs = untimed { Array.new(count) { fresh_env(env) } }
  envs.each { |request_env| respond(app, request_env) }
end

# Fails the benchmark unless +app+ answers +env+ with +status+ (and a
# body that includes +text+), so that each benchmark measures the path
# that it's named for, not a 404 or an error.
def check(app, env, status, text = nil)
  got, body = respond(app, fresh_env(env))
  return if got == status && (text.nil? || body.include?(text))

  raise "#{env[Rack::REQUEST_METHOD]} #{env[Rack::PATH_INFO]}: expected #{status}, got #{got}: #{body[0, 300]}"
end

# Sets up a benchmark of requests for +env+ to +app+, checked to answer
# +status+, in a `once` block of the benchmark.
def prepare(app, env, status, text = nil)
  check(app, env, status, text)
  @app = app
  @env = env
end
