Upgrading Grape
===============

### Upgrading to >= 4.0.0

#### `forward_match` is no longer exposed on routes

`forward_match` is an internal, construction-time detail that decides how a route matches incoming paths (a prefix match for mounted Rack apps, the compiled pattern otherwise). It is now passed to `Grape::Router::Route` as a keyword argument and derived from the mounted app instead of being carried in the route's options.

As a result it is no longer readable through `route.options[:forward_match]` or the `route.forward_match` reader — both previously returned the flag. Nothing in Grape consumed either, so this only affects code that introspected routes directly; there is no replacement, as the value is now purely internal.

#### `Grape::Endpoint.new` takes `http_methods:` instead of `method:`

`Grape::Endpoint.new` now receives the HTTP verb(s) under the `http_methods:` keyword instead of `method:`, matching the name used everywhere else. If you build endpoints directly (uncommon — this is an internal API normally driven by the routing DSL), rename the keyword:

```ruby
# before
Grape::Endpoint.new(settings, method: :get, path: '/foo', for: self)

# after
Grape::Endpoint.new(settings, http_methods: :get, path: '/foo', for: self)
```

Relatedly, an endpoint's public `options` Hash no longer carries `:method` or `:path`. Nothing in Grape read `:method`, and the only reader of `:path` was an internal test; both values are available from the route instead — `route.request_method` for the verb and `route.path` for the (compiled) path, which is what grape-swagger and other introspection already use. The raw definition-time path array is no longer exposed on the endpoint.

#### `Grape::Endpoint.new` takes `api:` instead of `for:`

The keyword identifying the API an endpoint belongs to has been renamed from `for:` — a reserved word whose value can't be referenced as a local — to `api:`:

```ruby
# before
Grape::Endpoint.new(settings, http_methods: :get, path: '/foo', for: my_api)

# after
Grape::Endpoint.new(settings, http_methods: :get, path: '/foo', api: my_api)
```

The owning API is no longer carried on the endpoint's public `options` Hash — `endpoint.options[:for]` is gone. Use the new `endpoint.api` reader instead.

#### Route metadata is exposed through readers, not the `options` Hash

A route's computed metadata — `version`, `namespace`, `prefix`, `requirements`, `anchor` and `settings` — is now exposed through plain readers instead of being merged into the route's `options` Hash. `namespace`, `prefix` and `settings` are passed to `Grape::Router::Route` as explicit keyword arguments; `version`, `anchor` and `requirements` are read from the route's pattern (they shape how it matches).

The readers are unchanged — keep using them:

```ruby
route.version       # => 'v1'
route.namespace     # => '/things'
route.prefix        # => 'api'
route.requirements  # => {}
route.anchor        # => true
route.settings      # => { ... }
```

What changed is the raw bag. `route.options` now holds only what was declared for the route, so it no longer carries the *computed* values for these keys — `route.options[:version]`, `[:namespace]`, `[:prefix]` and `[:settings]` return `nil`. Nothing in Grape or grape-swagger read them that way (grape-swagger uses the `route.prefix` and `route.settings` readers). `requirements` and `anchor` — which can be supplied as route options (e.g. a mount's `anchor: false`) — are covered separately below: they too are now first-class endpoint inputs and likewise no longer appear in `route.options`. The effective value always comes from the reader.

#### `Grape::Endpoint` no longer accepts a `format:` keyword

The `:format` member was removed from the endpoint's internal `Options`. Nothing ever passed `format:` to `Grape::Endpoint.new` — `config.format` was always `nil` — so this has no runtime effect (the `(.:format)`/`(.json)` route suffix comes from `Grape::Path`, not from this value). But `Grape::Endpoint.new(..., format: …)` now raises `unknown keyword: :format` instead of silently ignoring it.

`Grape::Router::Pattern#initialize` no longer accepts `format:` either. It was never given a non-`nil` value — a route's `:format` capture comes from the path suffix built by `Grape::Path`, not from the pattern — so the keyword was dead. `Grape::Router::Pattern.new(..., format: …)` now raises `unknown keyword: :format`.

#### `desc` no longer populates `namespace_setting(:description)`

`desc` used to store its settings under both the route scope (`route_setting(:description)`) and the namespace scope (`namespace_setting(:description)`). The namespace copy was write-only — the namespace scope isn't wired for inheritance and nothing in Grape or grape-swagger ever read it — so `desc` now writes only the route scope. `namespace_setting(:description)` returns `nil`; read a route's description through `route_setting(:description)` or the `route.description` reader.
#### `Grape::Router::Route#params` no longer takes an argument

`Route#params` used to do two jobs depending on its argument: `route.params(input)` extracted param values from a matched request path, while `route.params` (no argument) returned the route's declared param definitions. These are now separate methods:

```ruby
route.params            # declared param definitions, keyed by name (unchanged)
route.params_for(input) # values extracted from a matched path (was route.params(input))
```

The no-argument form is unchanged — grape-swagger and other documentation consumers keep using `route.params`. Only the value-extraction form moved, and it is internal to the router; if you called `route.params(input)` directly, switch to `route.params_for(input)`.

#### `params` is a first-class endpoint input, no longer in `route.options`

A route's declared params were previously carried inside the `route_options` bag and reachable as `route.options[:params]`. They are now composed into their own endpoint input (`Grape::Endpoint::Options` gains a `:params` member and `Grape::Endpoint.new` a `params:` keyword) and exposed only through `route.params`. `route.options[:params]` now returns `nil`. Nothing in Grape or grape-swagger read it that way — grape-swagger uses the `route.params` method — so this only affects code that reached into the options Hash for params directly.

#### `requirements` and `anchor` are first-class endpoint inputs, no longer in `route.options`

Like `params` above, a route's `requirements` and `anchor` were previously carried inside the `route_options` bag. They are now composed into their own endpoint inputs (`Grape::Endpoint::Options` gains `:requirements` and `:anchor` members, and `Grape::Endpoint.new` gains `requirements:` and `anchor:` keywords) and exposed only through the `route.requirements` and `route.anchor` readers. `route.options[:requirements]` and `route.options[:anchor]` now return `nil` — including for a mount's `anchor: false`. Nothing in Grape or grape-swagger read them that way, so this only affects code that reached into the options Hash for these keys directly.

#### Callback filters are recorded through `InheritableSetting` accessors

The filter blocks registered by `before`, `before_validation`, `after_validation`, `after` and `finally` are now recorded and read through dedicated accessors on `Grape::Util::InheritableSetting` — `add_callback(name, block)` to record, and `callbacks` returning a Hash keyed by the DSL method names (`callbacks[:before]`, `callbacks[:finally]`, …) — instead of raw `namespace_stackable` keys, following the same move made for rescue handlers. The keys' storage is unchanged for now, so `namespace_stackable[:befores]` and friends still return the same values, but the pluralized keys should be considered internal.

### Upgrading to >= 3.3

#### Minimum required Ruby is now 3.3

Grape no longer supports Ruby 3.2; 3.3 is now the minimum (`required_ruby_version = '>= 3.3'`). Upgrade your runtime to Ruby 3.3 or newer before bumping Grape.

#### `mustermann-grape` is no longer a dependency

Grape's path-pattern grammar (previously the `mustermann-grape` gem) now lives in Grape itself as `Grape::Router::MustermannPattern`, and Grape depends on `mustermann` directly. This is transparent for normal Grape usage.

The inlined class is no longer registered as a Mustermann type, so if your app called `Mustermann.new(pattern, type: :grape)` and relied on Grape loading `mustermann-grape` for you, add it to your Gemfile explicitly:

```ruby
gem 'mustermann-grape'
```

#### `Grape::Exceptions::ValidationErrors.new` keyword renamed `errors:` → `exceptions:`

`Grape::Exceptions::ValidationErrors#initialize` now takes its input array under the `exceptions:` keyword instead of `errors:`. The kwarg accepts a mix of `Grape::Exceptions::Validation` and `Grape::Exceptions::ValidationArrayErrors` instances; `ValidationArrayErrors` wrappers are flattened internally via `flat_map(&:errors)`. The `errors` reader on the constructed instance (the grouped `{params => [Validation, ...]}` Hash) is unchanged.

```ruby
# before
Grape::Exceptions::ValidationErrors.new(errors: [validation, validation_array_errors], headers:)

# after
Grape::Exceptions::ValidationErrors.new(exceptions: [validation, validation_array_errors], headers:)
#### `Grape::Exceptions::ValidationErrors` no longer mixes in `Enumerable`

`Grape::Exceptions::ValidationErrors` no longer includes `Enumerable` and no longer defines a public `#each`. The Enumerable surface (`#each`, `#map`, `#select`, `#to_a`, etc.) was undocumented and untested; the documented accessors — `#errors`, `#full_messages`, `#message`, `#as_json` — are unchanged.

If a `rescue_from` block iterated over the exception instance, switch to `#errors`:

```ruby
# before
rescue_from Grape::Exceptions::ValidationErrors do |e|
  e.each { |attribute, error| ... }
end

# after
rescue_from Grape::Exceptions::ValidationErrors do |e|
  e.errors.each do |attributes, errs|
    errs.each { |error| ... }
  end
end
```

#### `rescue_from` rejects meta selectors mixed with exception classes

`rescue_from` used to silently drop additional exception classes when its first argument was a meta selector (`:all`, `:grape_exceptions`, `:internal_grape_exceptions`). It now raises `ArgumentError` so the misuse is caught at definition time:

```ruby
# previously: MyError was silently dropped — only :all took effect
rescue_from :all, MyError, with: :handler

# now: ArgumentError ("rescue_from :all does not accept additional arguments")
# split into two declarations instead:
rescue_from :all, with: :handler
rescue_from MyError, with: :other_handler
```

Calls that only use one meta selector or only use exception classes (the documented forms) are unaffected.

#### `auth`, `http_basic` and `http_digest` now take keyword arguments

`Grape::Middleware::Auth::DSL#auth`, `#http_basic` and `#http_digest` now accept their options as keyword arguments instead of a positional `Hash`. Calls using bare keyword syntax or a block are unaffected:

```ruby
http_basic realm: 'API' do |u, p|
  # ...
end

auth :http_digest, realm: 'API', opaque: 'secret', &proc
```

Passing a positional options `Hash` still works but is deprecated and will be removed in a future release:

```ruby
# deprecated
http_basic({ realm: 'API' })
auth :http_digest, { realm: 'API', opaque: 'secret' }

# preferred
http_basic(realm: 'API')
auth :http_digest, realm: 'API', opaque: 'secret'
```

#### Middleware options now route through per-class `Options` `Data` value objects

`Grape::Middleware::Error`, `Grape::Middleware::Formatter`, and `Grape::Middleware::Versioner::Base` each declare an `Options` `Data.define` and route their `**options` kwargs through it on `initialize`. This means **unknown kwargs now raise `ArgumentError`** instead of being silently swallowed:

```ruby
# previously: silently swallowed (Formatter doesn't actually read :rescue_options)
Grape::Middleware::Formatter.new(app, rescue_options: { backtrace: true })

# now: ArgumentError (unknown keyword: :rescue_options)
```

Each `Options` class accepts exactly the kwargs the middleware actually reads. The supported sets:

- `Middleware::Error::Options`: `all_rescue_handler`, `base_only_rescue_handlers`, `content_types`, `default_error_formatter`, `default_message`, `default_status`, `error_formatters`, `format`, `grape_exceptions_rescue_handler`, `internal_grape_exceptions_rescue_handler`, `rescue_all`, `rescue_grape_exceptions`, `rescue_handlers`, `rescue_options`.
- `Middleware::Formatter::Options`: `content_types`, `default_format`, `format`, `formatters`, `parsers`.
- `Middleware::Versioner::Base::Options`: `content_types`, `format`, `mount_path`, `pattern`, `prefix`, `version_options`, `versions`.

The `Hash`-based `options` reader on `Grape::Middleware::Base` continues to return a frozen Hash representation of the Data (`config.to_h.freeze`) for back-compat with subclasses that read `options[:key]`. A new `config` reader exposes the typed Data instance — prefer the named accessors going forward:

```ruby
# back-compat (still works)
options[:format]

# preferred
config.format
# or, on converted middlewares, just `format` (provided via def_delegators)
```

`Options#[]` is defined as a Hash-style shim with a deprecation warning so legacy `data[:key]` callers get a migration nudge:

```ruby
# emits Grape.deprecator warning
Grape::Middleware::Error::Options.new[:format]
```

#### `DEFAULT_OPTIONS` constants on converted middlewares are deprecated

`Grape::Middleware::Error::DEFAULT_OPTIONS`, `Grape::Middleware::Formatter::DEFAULT_OPTIONS`, and `Grape::Middleware::Versioner::Base::DEFAULT_OPTIONS` still exist as a frozen `Hash` representation of the `Options` defaults (`Options.new.to_h.freeze`), for back-compat with any code that referenced these constants directly. They will be removed in a future release; introspect the `Options` `Data` class itself instead.

#### `Grape::Middleware::Globals` removed

`Grape::Middleware::Globals` and the three env constants it set (`Grape::Env::GRAPE_REQUEST`, `Grape::Env::GRAPE_REQUEST_HEADERS`, `Grape::Env::GRAPE_REQUEST_PARAMS`) have been deleted. The middleware was introduced in 2013 (commit `9987090b`) but never mounted by Grape's own stack — the `Grape::Request` it built is now constructed directly inside `Grape::Endpoint`. Nothing in `lib/` read those env keys.

If you mounted `Grape::Middleware::Globals` in your own Rack stack to populate `env['grape.request']` for downstream middleware, replicate it locally:

```ruby
class MyGlobals
  def initialize(app); @app = app; end

  def call(env)
    request = Grape::Request.new(env)
    env['grape.request'] = request
    env['grape.request.headers'] = request.headers
    env['grape.request.params'] = request.params if env['rack.input']
    @app.call(env)
  end
end
```

The original implementation is preserved in git history at [`6b4111b3:lib/grape/middleware/globals.rb`](https://github.com/ruby-grape/grape/blob/6b4111b3/lib/grape/middleware/globals.rb).

#### `error_formatter` now receives a `Grape::Exceptions::ErrorResponse` value object

Custom error formatters now receive a frozen `Grape::Exceptions::ErrorResponse` as the `error:` keyword argument, alongside three request-time context kwargs. The new signature:

```ruby
def call(error:, env: nil, include_backtrace: false, include_original_exception: false)
```

`error` is the same value object the middleware uses internally, with `status` / `message` / `headers` / `backtrace` / `original_exception` accessors. The two `include_*` booleans are forwarded from the matching `rescue_from` options (previously buried inside `options[:rescue_options]`).

Existing positional formatters break and need to be updated:

```ruby
# Before
error_formatter :txt, ->(message, backtrace, options, env, original_exception) { ... }

module CustomFormatter
  def self.call(message, backtrace, options, env, original_exception)
    ...
  end
end

# After — pick fields off `error`
error_formatter :txt, ->(error:, **) { "[#{error.status}] #{error.message}" }

module CustomFormatter
  def self.call(error:, **)
    { status: error.status, message: error.message, backtrace: error.backtrace }
  end
end
```

Migration:

| Old positional arg | New |
| --- | --- |
| `message` | `error.message` |
| `backtrace` | `error.backtrace` |
| `original_exception` | `error.original_exception` |
| `options[:rescue_options][:backtrace]` | `include_backtrace` (kwarg) |
| `options[:rescue_options][:original_exception]` | `include_original_exception` (kwarg) |
| `env` | `env` (kwarg, still passed) |
| HTTP status | `error.status` (newly exposed) |
| Response headers | `error.headers` (newly exposed) |

The remaining middleware-options keys (`default_status`, `format`, `rescue_handlers`, …) were framework-internal and have never been part of the documented contract.

The change resolves [#2527](https://github.com/ruby-grape/grape/issues/2527): the HTTP `status` and the response `headers` are now part of the formatter contract, so JSON:API–style error bodies (which embed the status code) and header-aware formatters can be written without reaching into `env[Grape::Env::API_ENDPOINT]`.

#### `version` now takes explicit keyword arguments

`version` previously accepted `**options` and silently ignored any keys it didn't use. It now declares its options explicitly:

```ruby
def version(*args, using: :path, cascade: true, parameter: 'apiver', strict: false, vendor: nil, &block)
```

Passing an unrecognised keyword now raises `ArgumentError` instead of being swallowed. The most common offender is `format:` — it was never a `version` option (response format is set with `format`/`default_format`, and header-versioned requests carry the format in their `Accept` header), but the old splat let `version 'v1', using: :header, vendor: 'x', format: :json` through as a no-op.

```ruby
# Before — `format:` silently ignored
version 'v1', using: :header, vendor: 'x', format: :json

# After
version 'v1', using: :header, vendor: 'x'   # set responses with `format :json` / `default_format :json`
```

Recognized keys are `using:`, `cascade:`, `parameter:`, `strict:`, `vendor:`. Calls using only those are unaffected.

#### `Grape::Middleware::Base#options` is now frozen

`@options` is frozen at the end of `Grape::Middleware::Base#initialize` (after `merge_default_options`). The hash is initialized once and treated as immutable for the lifetime of the middleware. Custom middleware that mutates `options[...]` at runtime will now raise `FrozenError`.

If your custom middleware was patching its own options on the fly:

```ruby
# Before
class MyMiddleware < Grape::Middleware::Base
  def before
    options[:flag] = compute_flag
    # ...
  end
end

# After — store mutable runtime state on a dedicated ivar
class MyMiddleware < Grape::Middleware::Base
  def before
    @flag = compute_flag
    # ...
  end
end
```

Reading `options[...]` is unchanged.

#### Throw `:error` payloads are now `Grape::Exceptions::ErrorResponse`

The payload thrown via `throw :error, ...` is now a `Grape::Exceptions::ErrorResponse` value object instead of a `Hash`. If you `catch(:error)` and inspect the payload, switch from `payload[:status]` to `payload.status` (or `payload[:message]` to `payload.message`, etc.). User-defined `throw :error, hash` calls continue to work — `Middleware::Error#error_response` coerces Hashes, exceptions, and `ErrorResponse` instances at the boundary.

Returning or throwing a `Hash` with `:message`, `:status`, and `:headers` from a `rescue_from` handler is now deprecated and will be removed in a future release. Use `error!(...)` or return/throw a `Grape::Exceptions::ErrorResponse` instead.

#### `Grape::Request#grape_routing_args` has been removed

`grape_routing_args` was previously public to support third-party `params_builder` extensions, which have since been removed. With no remaining callers, the method has been removed. If you were calling it externally, read `env[Grape::Env::GRAPE_ROUTING_ARGS]` directly.

#### `endpoint_run_filters.grape` notification no longer fired for empty filter lists

`ActiveSupport::Notifications` subscribers listening to `endpoint_run_filters.grape` will no longer receive an event when the filter list for a given phase (`:before`, `:before_validation`, `:after_validation`, `:after`, `:finally`) is empty. Previously every phase emitted an event on every request regardless of whether any filters were registered. If you relied on these events to infer per-phase timing, subscribe to `endpoint_run.grape` (which always fires once per request) or register a no-op filter to keep the phase instrumented.

#### `Grape::Endpoint.before_each` moved to `Grape::Testing`

`Grape::Endpoint.before_each` and `Grape::Endpoint.reset_before_each` are now only available after requiring `grape/testing`. This module is intended for test environments only and is not loaded by default.

Add the following to your test helper:

```ruby
require 'grape/testing'
```

The `before_each` method now always requires a block — calling it without one raises `ArgumentError`. To clear registered hooks, use the new dedicated `reset_before_each` method:

```ruby
# Before
after { Grape::Endpoint.before_each nil }

# After
after { Grape::Endpoint.reset_before_each }
```

#### `Grape::Endpoint#logger` now returns the API's configured logger

Calling `logger` inside a route handler, filter (`before` / `before_validation` / `after_validation` / `after` / `finally`), or `rescue_from` block previously raised `NoMethodError` unless the application defined a helper:

```ruby
class MyAPI < Grape::API
  logger Logger.new($stdout)

  helpers do
    def logger
      MyAPI.logger
    end
  end
end
```

`Grape::Endpoint` now exposes `#logger` directly, so the helper is no longer necessary:

```ruby
class MyAPI < Grape::API
  logger Logger.new($stdout)
  # logger is now reachable inside route handlers, filters, and rescue_from blocks
end
```

**Helper override still wins.** Helpers are mixed into the endpoint's singleton class via `singleton_class.include(@helpers)`, and singleton-class methods take precedence over instance methods on `Grape::Endpoint`. If your application already defines `logger` in a `helpers` block (or a module included via `helpers`), that definition continues to override `Endpoint#logger`. You can safely keep the helper or remove it — both paths produce the same result for the canonical `MyAPI.logger` case above.

**Behaviour change for code that didn't define a helper.** If your code references `logger` inside an endpoint context *without* a corresponding `helpers` definition, that call previously raised `NoMethodError` and now returns the API's configured logger. This is almost always the intended behaviour, but if you were relying on the `NoMethodError` (for instance to short-circuit logging in test environments via `rescue NoMethodError`), update your code to check `respond_to?(:logger)` or to gate logging on a feature flag.

#### Exceptions raised inside `rescue_from` blocks are now caught

Previously, an exception raised inside a `rescue_from` block was uncaught and bubbled up to Rack, producing the Rack default 500 page. The framework now catches and routes it:

1. If the re-raised exception's class has a registered `rescue_from` handler, that handler runs (one redispatch only — a second raise stops the chain).
2. If the re-raised exception is a `Grape::Exceptions::Base` subclass, it is rendered via the default Grape error path with its own `status` and `message`.
3. Otherwise, the original exception is exposed on `env['grape.exception']` for upstream Rack middleware to observe, and the response is a generic `Grape::Exceptions::InternalServerError` (`500 Internal Server Error`) — the original exception's message is **not** rendered to the API consumer.

This means deliberate re-raises in a `rescue_from` block (e.g. translating one exception class into another) now compose with the rest of your `rescue_from` configuration, and accidental crashes (typos, `NoMethodError`, …) no longer leak internal detail to API consumers.

The framework deliberately does **not** log unhandled internal exceptions itself — formatting and destination are application concerns. To log, forward to an error tracker, or customize the response shape for these errors, register a `rescue_from :internal_grape_exceptions` handler:

```ruby
rescue_from :internal_grape_exceptions do |e|
  Sentry.capture_exception(e)
  error!({ message: 'Something went wrong' }, 500)
end
```

When this handler is registered, the framework hands the original exception to you and you own the response shape entirely.

If you relied on the old behaviour and want raw exception messages exposed in development, register a catch-all handler:

```ruby
rescue_from StandardError do |e|
  error!({ message: e.message, class: e.class.name }, 500)
end
```


### Upgrading to >= 3.2

#### Rack parameter parsing errors now raise `Grape::Exceptions::RequestError`

Rack errors raised during parameter parsing (malformed multipart, parameter type conflicts, encoding issues, etc.) are now wrapped in `Grape::Exceptions::RequestError` instead of their previous specific exception classes (`Grape::Exceptions::EmptyMessageBody`, `Grape::Exceptions::TooManyMultipartFiles`, `Grape::Exceptions::TooDeepParameters`, `Grape::Exceptions::ConflictingTypes`, `Grape::Exceptions::InvalidParameters`). Those classes have been removed.

If you rescue any of these specific exceptions, update your rescue clauses to use `Grape::Exceptions::RequestError`:

```ruby
# Before
rescue Grape::Exceptions::ConflictingTypes, Grape::Exceptions::TooDeepParameters => e
  # ...

# After
rescue Grape::Exceptions::RequestError => e
  # ...
```

The error message is now forwarded directly from Rack rather than translated through Grape's locale system. On Rack 3, all Rack bad-request errors share the `Rack::BadRequest` marker module and are covered by a single rescue.

#### `endpoint_run_validators.grape` notification no longer fired when there are no validators

`ActiveSupport::Notifications` subscribers listening to `endpoint_run_validators.grape` will no longer receive an event for endpoints that have no validators. If you rely on this notification to measure every request, subscribe to `endpoint_run.grape` instead, which always fires.

#### Custom validators: use `default_message_key` and `validation_error!`

Validators are now instantiated once at definition time and frozen. Any setup should happen in `initialize`, not in `validate_param!`.

If your custom validator did work in `validate_param!` that only depends on the validator's options (not the param value), move it to `initialize`. A common case is compiling a value derived from options — for example, building a `Regexp`. Previously this may have been cached back into `@options`, which now raises `FrozenError` since `@options` and its nested values are deep-frozen by the base class:

**Before:**
```ruby
class MyValidator < Grape::Validations::Validators::Base
  def validate_param!(attr_name, params)
    # raises FrozenError: @options is frozen, cannot store compiled pattern back into it
    @options[:compiled] ||= Regexp.new(@options[:pattern])
    validation_error!(attr_name) unless params[attr_name].match?(@options[:compiled])
  end
end
```

**After:**
```ruby
class MyValidator < Grape::Validations::Validators::Base
  def initialize(attrs, options, required, scope, opts)
    super
    @pattern = Regexp.new(@options[:pattern]).freeze
  end

  def validate_param!(attr_name, params)
    validation_error!(attr_name) unless params[attr_name].match?(@pattern)
  end
end
```

Any Array or Hash derived from options and stored in an ivar should be frozen, since the validator instance is shared across requests. `@options` itself (and any nested Hash/Array/String values within it) is deep-frozen by the base class, so mutations like `@options[:values] << 'extra'` will also raise a `FrozenError`.

#### Custom validators: rename `@option` to `@options`

The instance variable holding the validator's option value has been renamed from `@option` to `@options`. `@option` remains as an alias for backwards compatibility but will be removed in the next major release. Update any custom validators to use `@options` instead.

Several new helpers are available — see [Available helpers](README.md#available-helpers) in the README for full documentation and examples.

#### `with` now uses keyword arguments

The `with` DSL method now uses `**opts` instead of a positional hash. Calls using bare keyword syntax are unaffected:

```ruby
# still works
with(type: String, documentation: { in: 'body' }) { ... }
```

However, passing an explicit hash literal will now raise an `ArgumentError`:

```ruby
# raises ArgumentError
with({ type: String }) { ... }
```

See [#2663](https://github.com/ruby-grape/grape/pull/2663) for more information.

#### Custom validators: use `translate` instead of `I18n` directly

`Grape::Util::Translation` is now included in `Grape::Validations::Validators::Base`. Custom validators that previously called `I18n.t` or `I18n.translate` directly should switch to the `translate`, which provides the same `:en` fallback logic used by all built-in validators.

Key points:
- `scope` defaults to `'grape.errors.messages'` — no need to specify it for standard error message keys.
- Interpolation variables are passed directly to I18n.
- `format` is no longer needed — `translate` returns the fully interpolated string.

```ruby
# Before
raise Grape::Exceptions::Validation.new(
  params: [@scope.full_name(attr_name)],
  message: format(I18n.t(:my_key, scope: 'grape.errors.messages'), min: 2, max: 10)
)

# After
raise Grape::Exceptions::Validation.new(
  params: [@scope.full_name(attr_name)],
  message: translate(:my_key, min: 2, max: 10)
)
```

See [#2662](https://github.com/ruby-grape/grape/pull/2662) for more information.

### Upgrading to >= 3.1

#### Explicit kwargs for `namespace` and `route_param`

The `API#namespace` and `route_param` methods are now defined with `**options` instead of `options = {}`. In addtion, `requirements` in explicitly defined so it's not in `options` anymore. You can still call `requirements` like before but `options[:requirements]` will be empty. For `route_param`, `type` is also an explicit parameter so it's not in `options` anymore. See [#2647](https://github.com/ruby-grape/grape/pull/2647) for more information.

#### ParamsBuilder Grape::Extensions

Deprecated [ParamsBuilder's extensions](https://github.com/ruby-grape/grape/blob/master/UPGRADING.md#params-builder) have been removed.

#### Enhanced API compile!

Endpoints are now "compiled" instead of lazy loaded. Historically, when calling `YourAPI.compile!` in `config.ru` (or just receiving the first API call), only routing was compiled see [Grape::Router#compile!](https://github.com/ruby-grape/grape/blob/bf90e95c3b17c415c944363b1c07eb9727089ee7/lib/grape/router.rb#L41-L54) and endpoints were lazy loaded. Now, it's part of the API compilation. See [#2645](https://github.com/ruby-grape/grape/pull/2645) for more information.

### Upgrading to >= 3.0.0

#### Ruby 3+ Argument Delegation Modernization

Grape has been modernized to use Ruby 3+'s preferred argument delegation patterns. This change replaces `args.extract_options!` with explicit `**kwargs` parameters throughout the codebase.

- All DSL methods now use explicit keyword arguments (`**kwargs`) instead of extracting options from mixed argument lists
- Method signatures are now more explicit and follow Ruby 3+ best practices
- The `active_support/core_ext/array/extract_options` dependency has been removed

This is a modernization effort that improves code quality while maintaining full backward compatibility.

See [#2618](https://github.com/ruby-grape/grape/pull/2618) for more information.

#### Configuration API Migration from ActiveSupport::Configurable to Dry::Configurable

Grape has migrated from `ActiveSupport::Configurable` to `Dry::Configurable` for its configuration system since its [deprecated](https://github.com/rails/rails/blob/1cdd190a25e483b65f1f25bbd0f13a25d696b461/activesupport/lib/active_support/configurable.rb#L3-L7).

See [#2617](https://github.com/ruby-grape/grape/pull/2617) for more information.

#### Endpoint execution simplified and `return` deprecated

Executing a endpoint's block has been simplified and calling `return` in it has been deprecated. Use `next` instead.

See [#2577](https://github.com/ruby-grape/grape/pull/2577) for more information.

#### Old Deprecations Clean Up

- `rack_response` has been removed in favor of using `error!`.
- `Grape::Exceptions::MissingGroupType` and `Grape::Exceptions::UnsupportedGroupType` aliases `MissingGroupTypeError and `UnsupportedGroupType` have been removed.
- `Grape::Validations::Base` has been removed in favor of `Grape::Validations::Validators::Base`.

See [2573](https://github.com/ruby-grape/grape/pull/2573) for more information.

### Upgrading to >= 2.4.0

#### Grape::Middleware::Auth::Base
`type` is now validated at compile time and will raise a `Grape::Exceptions::UnknownAuthStrategy` if unknown.

#### Grape::Middleware::Base

- Second argument `options` is now a double splat (**) instead of single splat (*). If you're redefining `initialize` in your middleware and/or calling `super` in it, you might have to adapt the signature and the `super` call. Also, you might have to remove `{}` if you're pass `options` as a literal `Hash` or add `**` if you're using a variable.
- `Grape::Middleware::Helpers` has been removed. The equivalent method `context` is now part of `Grape::Middleware::Base`.

#### Grape::Http::Headers, Grape::Util::Lazy::Object

Both have been removed. See [2554](https://github.com/ruby-grape/grape/pull/2554).
Here are the notable changes:

- Constants like `HTTP_ACCEPT` have been replaced by their literal value.
- `SUPPORTED_METHODS` has been moved to `Grape` module.
- `HTTP_HEADERS` has been moved to `Grape::Request` and renamed `KNOWN_HEADERS`. The last has been refreshed with new headers, and it's not lazy anymore.
- `SUPPORTED_METHODS_WITHOUT_OPTIONS` and `find_supported_method` have been removed.

#### Grape::Middleware::Base

- Constant `TEXT_HTML` has been removed in favor of using literal string 'text/html'.
- `rack_request` and `query_params` have been added. Feel free to call these in your middlewares.

#### Params Builder

- Passing a class to `build_with` or `Grape.config.param_builder` has been deprecated in favor of a symbolized short_name. See `SHORTNAME_LOOKUP` in [params_builder](lib/grape/params_builder.rb).
- Including Grape's extensions like `Grape::Extensions::Hashie::Mash::ParamBuilder` has been deprecated in favor of using `build_with` at the route level.

#### Accept Header Negotiation Harmonized

[Accept](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Accept) header is now fully interpreted through `Rack::Utils.best_q_match` which is following [RFC2616 14.1](https://datatracker.ietf.org/doc/html/rfc2616#section-14.1). Since [Grape 2.1.0](https://github.com/ruby-grape/grape/blob/master/CHANGELOG.md#210-20240615), the [header versioning strategy](https://github.com/ruby-grape/grape?tab=readme-ov-file#header) was adhering to it, but `Grape::Middleware::Formatter` never did.

Your API might act differently since it will strictly follow the [RFC2616 14.1](https://datatracker.ietf.org/doc/html/rfc2616#section-14.1) when interpreting the `Accept` header. Here are the differences:

##### Invalid or missing quality ranking
The following used to yield `application/xml` and now will yield `application/json` as the preferred media type:
- `application/json;q=invalid,application/xml;q=0.5`
- `application/json,application/xml;q=1.0`

For the invalid case, the value `invalid` was automatically `to_f` and `invalid.to_f` equals `0.0`. Now, since it doesn't match [Rack's regex](https://github.com/rack/rack/blob/3-1-stable/lib/rack/utils.rb#L138), its interpreted as non provided and its quality ranking equals 1.0.

For the non provided case, 1.0 was automatically assigned and in a case of multiple best matches, the first was returned based on Ruby's sort_by `quality`. Now, 1.0 is still assigned and the last is returned in case of multiple best matches. See [Rack's implementation](https://github.com/rack/rack/blob/e8f47608668d507e0f231a932fa37c9ca551c0a5/lib/rack/utils.rb#L167) of the RFC.

##### Considering the closest generic when vendor tree
Excluding the [header versioning strategy](https://github.com/ruby-grape/grape?tab=readme-ov-file#header), whenever a media type with the [vendor tree](https://datatracker.ietf.org/doc/html/rfc6838#section-3.2) leading facet `vnd.` like `application/vnd.api+json` was provided, Grape would also consider its closest generic when negotiating. In that case, `application/json` was added to the negotiation. Now, it will just consider the provided media types without considering any closest generics, and you'll need to [register](https://github.com/ruby-grape/grape?tab=readme-ov-file#api-formats) it.
You can find the official vendor tree registrations on [IANA](https://www.iana.org/assignments/media-types/media-types.xhtml)

#### Custom Validators

If you now receive an error of `'Grape::Validations.require_validator': unknown validator: your_custom_validation (Grape::Exceptions::UnknownValidator)` after upgrading to 2.4.0 then you will need to ensure that you require the `your_custom_validation` file before your Grape API code is loaded.

See [2533](https://github.com/ruby-grape/grape/issues/2533) for more information.

### Upgrading to >= 2.3.0

### `content_type` vs `api.format` inside API

Before 2.3.0, `content_type` had priority over `env['api.format']` when set in an API, which was incorrect. The priority has been flipped and `env['api.format']` will be checked first.
In addition, the function `api_format` has been added. Instead of setting `env['api.format']` directly, you can call `api_format`.
See [#2506](https://github.com/ruby-grape/grape/pull/2506) for more information.

#### Remove Deprecated Methods and Options

- Deprecated `file` method has been removed. Use `send_file` or `stream`.
See [#2500](https://github.com/ruby-grape/grape/pull/2500) for more information.

- The `except` and `proc` options have been removed from the `values` validator. Use `except_values` validator or assign `proc` directly to `values`.
See [#2501](https://github.com/ruby-grape/grape/pull/2501) for more information.

- `Passing an options hash and a block to 'desc'` deprecation has been removed. Move all hash options to block instead.
See [#2502](https://github.com/ruby-grape/grape/pull/2502) for more information.

### Upgrading to >= 2.2.0

### `Length` validator

After Grape 2.2.0, `length` validator will only take effect for parameters with types that support `#length` method, will not throw `ArgumentError` exception.

See [#2464](https://github.com/ruby-grape/grape/pull/2464) for more information.

### Upgrading to >= 2.1.0

#### Optional Builder

The `builder` gem dependency has been made optional as it's only used when generating XML. If your code does, add `builder` to your `Gemfile`.

See [#2445](https://github.com/ruby-grape/grape/pull/2445) for more information.

#### Deep Merging of Parameter Attributes

Grape now uses `deep_merge` to combine parameter attributes within the `with` method. Previously, attributes defined at the parameter level would override those defined at the group level.
With deep merge, attributes are now combined, allowing for more detailed and nuanced API specifications.

For example:

```ruby
with(documentation: { in: 'body' }) do
  optional :vault, documentation: { default: 33 }
end
```

Before it was equivalent to:

```ruby
optional :vault, documentation: { default: 33 }
```

After it is an equivalent of:

```ruby
optional :vault, documentation: { in: 'body', default: 33 }
```

See [#2432](https://github.com/ruby-grape/grape/pull/2432) for more information.

#### Zeitwerk

Grape's autoloader has been updated and it's now based on [Zeitwerk](https://github.com/fxn/zeitwerk).
If you MP (Monkey Patch) some files and you're not following the [file structure](https://github.com/fxn/zeitwerk?tab=readme-ov-file#file-structure), you might end up with a Zeitwerk error.

See [#2363](https://github.com/ruby-grape/grape/pull/2363) for more information.

#### Changes in rescue_from

The `rack_response` method has been deprecated and the `error_response` method has been removed. Use `error!` instead.

See [#2414](https://github.com/ruby-grape/grape/pull/2414) for more information.

#### Change in parameters precedence

When using together with `Grape::Extensions::Hash::ParamBuilder`, `route_param` takes higher precedence over a regular parameter defined with same name, which now matches the default param builder behavior.

This was a regression introduced by [#2326](https://github.com/ruby-grape/grape/pull/2326) in Grape v1.8.0.

```ruby
Grape.configure do |config|
  config.param_builder = Grape::Extensions::Hash::ParamBuilder
end

params do
  requires :foo, type: String
end
route_param :foo do
  get do
    { value: params[:foo] }
  end
end
```

Request:

```bash
curl -X POST -H "Content-Type: application/json" localhost:9292/bar -d '{"foo": "baz"}'
```

Response prior to v1.8.0:

```json
{
  "value": "bar"
}
```

v1.8.0..v2.0.0:

```json
{
  "value": "baz"
}
```

v2.1.0+:

```json
{
  "value": "bar"
}
```

See [#2378](https://github.com/ruby-grape/grape/pull/2378) for details.

#### Grape::Router::Route.route_xxx methods have been removed

- `route_method` is accessible through `request_method`
- `route_path` is accessible through `path`
- Any other `route_xyz` are accessible through `options[xyz]`

#### Instance variables scope

Due to the changes done in [#2377](https://github.com/ruby-grape/grape/pull/2377), the instance variables defined inside each of the endpoints (or inside a `before` validator) are now accessible inside the `rescue_from`. The behavior of the instance variables was undefined until `2.1.0`.

If you were using the same variable name defined inside an endpoint or `before` validator inside a `rescue_from` handler, you need to take in mind that you can start getting different values or you can be overriding values.

Before:
```ruby
class TwitterAPI < Grape::API
  before do
    @var = 1
  end

  get '/' do
    puts @var # => 1
    raise
  end

  rescue_from :all do
    puts @var # => nil
  end
end
```

After:
```ruby
class TwitterAPI < Grape::API
  before do
    @var = 1
  end

  get '/' do
    puts @var # => 1
    raise
  end

  rescue_from :all do
    puts @var # => 1
  end
end
```

#### Recognizing Path

Grape now considers the types of the configured `route_params` in order to determine the endpoint that matches with the performed request.

So taking into account this `Grape::API` class

```ruby
class Books < Grape::API
  resource :books do
    route_param :id, type: Integer do
      # GET /books/:id
      get do
        #...
      end
    end

    resource :share do
      # POST /books/share
      post do
      # ....
      end
    end
  end
end
```

Before:
```ruby
API.recognize_path '/books/1' # => /books/:id
API.recognize_path '/books/share' # => /books/:id
API.recognize_path '/books/other' # => /books/:id
```

After:
```ruby
API.recognize_path '/books/1' # => /books/:id
API.recognize_path '/books/share' # => /books/share
API.recognize_path '/books/other' # => nil
```

This implies that before this changes, when you performed `/books/other` and it matched with the `/books/:id` endpoint, you get a `400 Bad Request` response because the type of the provided `:id` param was not an `Integer`. However, after upgrading to version `2.1.0` you will get a `404 Not Found` response, because there is not a defined endpoint that matches with `/books/other`.

See [#2379](https://github.com/ruby-grape/grape/pull/2379) for more information.

### Upgrading to >= 2.0.0

#### Headers

As per [rack/rack#1592](https://github.com/rack/rack/issues/1592) Rack 3 is following the HTTP/2+ semantics which require header names to be lower case. To avoid compatibility issues, starting with Grape 1.9.0, headers will be cased based on what version of Rack you are using.

Given this request:

```shell
curl -H "Content-Type: application/json" -H "Secret-Password: foo" ...
```

If you are using Rack 3 in your application then the headers will be set to:

```ruby
{ "content-type" => "application/json", "secret-password" => "foo"}
```

This means if you are checking for header values in your application, you would need to change your code to use downcased keys.

```ruby
get do
  # This would use headers['Secret-Password'] in Rack < 3
  error!('Unauthorized', 401) unless headers['secret-password'] == 'swordfish'
end
```

See [#2355](https://github.com/ruby-grape/grape/pull/2355) for more information.

#### Digest auth deprecation

Digest auth has been removed along with the deprecation of `Rack::Auth::Digest` in Rack 3.

See [#2294](https://github.com/ruby-grape/grape/issues/2294) for more information.

### Upgrading to >= 1.7.0

#### Exceptions renaming

The following exceptions has been renamed for consistency through exceptions naming :

* `MissingGroupTypeError` => `MissingGroupType`
* `UnsupportedGroupTypeError` => `UnsupportedGroupType`

See [#2227](https://github.com/ruby-grape/grape/pull/2227) for more information.

#### Handling Multipart Limit Errors

Rack supports a configurable limit on the number of files created from multipart parameters (`Rack::Utils.multipart_part_limit`) and raises an error if params are received that create too many files.  If you were handling the Rack error directly, Grape now wraps that error in `Grape::Execeptions::TooManyMultipartFiles`.  Additionally, Grape will return a 413 status code if the exception goes unhandled.

### Upgrading to >= 1.6.0

#### Parameter renaming with :as

Prior to 1.6.0 the [parameter renaming](https://github.com/ruby-grape/grape#renaming) with `:as` was directly touching the request payload ([`#params`](https://github.com/ruby-grape/grape#parameters)) while duplicating the old and the new key to be both available in the hash. This allowed clients to bypass any validation in case they knew the internal name of the parameter.  Unfortunately, in combination with [grape-swagger](https://github.com/ruby-grape/grape-swagger) the internal name (name set with `:as`) of the parameters were documented.

This behavior was fixed. Parameter renaming is now done when using the [`#declared(params)`](https://github.com/ruby-grape/grape#declared) parameters helper. This stops confusing validation/coercion behavior.

Here comes an illustration of the old and new behaviour as code:

```ruby
# (1) Rename a to b, while client sends +a+
optional :a, type: Integer, as: :b
params = { a: 1 }
declared(params, include_missing: false)
# expected => { b: 1 }
# actual   => { b: 1 }

# (2) Rename a to b, while client sends +b+
optional :a, type: Integer, as: :b, values: [1, 2, 3]
params = { b: '5' }
declared(params, include_missing: false)
# expected => { }        (>= 1.6.0)
# actual   => { b: '5' } (uncasted, unvalidated, <= 1.5.3)
```

Another implication of this change is the dependent parameter resolution. Prior to 1.6.0 the following code produced a `Grape::Exceptions::UnknownParameter` because `:a` was replaced by `:b`:

```ruby
params do
  optional :a, as: :b
  given :a do # (<= 1.5.3 you had to reference +:b+ here to make it work)
    requires :c
  end
end
```

This code now works without any errors, as the renaming is just an internal behaviour of the `#declared(params)` parameter helper.

See [#2189](https://github.com/ruby-grape/grape/pull/2189) for more information.

### Upgrading to >= 1.5.3

#### Nil value and coercion

Prior to 1.2.5 version passing a `nil` value for a parameter with a custom coercer would invoke the coercer, and not passing a parameter would not invoke it.
This behavior was not tested or documented. Version 1.3.0 quietly changed this behavior, in that `nil` values skipped the coercion. Version 1.5.3 fixes and documents this as follows:

```ruby
class Api < Grape::API
  params do
    optional :value, type: Integer, coerce_with: ->(val) { val || 0 }
  end

  get 'example' do
     params[:my_param]
  end
  get '/example', params: { value: nil }
  # 1.5.2 = nil
  # 1.5.3 = 0
  get '/example', params: {}
  # 1.5.2 = nil
  # 1.5.3 = nil
end
```
See [#2164](https://github.com/ruby-grape/grape/pull/2164) for more information.

### Upgrading to >= 1.5.1

#### Dependent params

If you use [dependent params](https://github.com/ruby-grape/grape#dependent-parameters) with
`Grape::Extensions::Hash::ParamBuilder`, make sure a parameter to be dependent on is set as a Symbol.
If a String is given, a parameter that other parameters depend on won't be found even if it is present.

_Correct_:
```ruby
given :matrix do
  # dependent params
end
```

_Wrong_:
```ruby
given 'matrix' do
  # dependent params
end
```

### Upgrading to >= 1.5.0

Prior to 1.3.3, the `declared` helper would always return the complete params structure if `include_missing=true` was set. In 1.3.3 a regression was introduced such that a missing Hash with or without nested parameters would always resolve to `{}`.

In 1.5.0 this behavior is reverted, so the whole params structure will always be available via `declared`, regardless of whether any params are passed.

The following rules now apply to the `declared` helper when params are missing and `include_missing=true`:

* Hash params with children will resolve to a Hash with keys for each declared child.
* Hash params with no children will resolve to `{}`.
* Set params will resolve to `Set.new`.
* Array params will resolve to `[]`.
* All other params will resolve to `nil`.

#### Example

```ruby
class Api < Grape::API
  params do
    optional :outer, type: Hash do
      optional :inner, type: Hash do
        optional :value, type: String
      end
    end
  end
  get 'example' do
    declared(params, include_missing: true)
  end
end
```

```
get '/example'
# 1.3.3 = {}
# 1.5.0 = {outer: {inner: {value:null}}}
```

For more information see [#2103](https://github.com/ruby-grape/grape/pull/2103).

### Upgrading to >= 1.4.0

#### Reworking stream and file and un-deprecating stream like-objects

Previously in 0.16 stream-like objects were deprecated. This release restores their functionality for use-cases other than file streaming.

This release deprecated `file` in favor of `sendfile` to better document its purpose.

To deliver a file via the Sendfile support in your web server and have the Rack::Sendfile middleware enabled. See [`Rack::Sendfile`](https://www.rubydoc.info/gems/rack/Rack/Sendfile).
```ruby
class API < Grape::API
  get '/' do
    sendfile '/path/to/file'
  end
end
```

Use `stream` to stream file content in chunks.

```ruby
class API < Grape::API
  get '/' do
    stream '/path/to/file'
  end
end
```

Or use `stream` to stream other kinds of content. In the following example a streamer class
streams paginated data from a database.

```ruby
class MyObject
  attr_accessor :result

  def initialize(query)
    @result = query
  end

  def each
    yield '['
    # Do paginated DB fetches and return each page formatted
    first = false
    result.find_in_batches do |records|
      yield process_records(records, first)
      first = false
    end
    yield ']'
  end

  def process_records(records, first)
    buffer = +''
    buffer << ',' unless first
    buffer << records.map(&:to_json).join(',')
    buffer
  end
end

class API < Grape::API
  get '/' do
    stream MyObject.new(Sprocket.all)
  end
end
```

### Upgrading to >= 1.3.3

#### Nil values for structures

Nil values have always been a special case when dealing with types, especially with the following structures:

- Array
- Hash
- Set

The behavior for these structures has changed throughout the latest releases. For example:

```ruby
class Api < Grape::API
  params do
    require :my_param, type: Array[Integer]
  end

  get 'example' do
     params[:my_param]
  end
  get '/example', params: { my_param: nil }
  # 1.3.3 = []
  # 1.3.2 = nil
end
```

For now on, `nil` values stay `nil` values for all types, including arrays, sets and hashes.

If you want to have the same behavior as 1.3.1, apply a `default` validator:

```ruby
class Api < Grape::API
  params do
    require :my_param, type: Array[Integer], default: []
  end

  get 'example' do
     params[:my_param]
  end
  get '/example', params: { my_param: nil } # => []
end
```

#### Default validator

Default validator is now applied for `nil` values.

```ruby
class Api < Grape::API
  params do
    requires :my_param, type: Integer, default: 0
  end

  get 'example' do
     params[:my_param]
  end
  get '/example', params: { my_param: nil } #=> before: nil, after: 0
end
```

### Upgrading to >= 1.3.0

You will need to upgrade to this version if you depend on `rack >= 2.1.0`.

#### Ruby

After adding dry-types, Ruby 2.4 or newer is required.

#### Coercion

[Virtus](https://github.com/solnic/virtus) has been replaced by [dry-types](https://dry-rb.org/gems/dry-types/1.2/) for parameter coercion. If your project depends on Virtus outside of Grape, explicitly add it to your `Gemfile`.

Here's an example of how to migrate a custom type from Virtus to dry-types:

```ruby
# Legacy Grape parser
class SecureUriType < Virtus::Attribute
  def coerce(input)
    URI.parse value
  end

  def value_coerced?(input)
    value.is_a? String
  end
end

params do
  requires :secure_uri, type: SecureUri
end
```

To use dry-types, we need to:

1. Remove the inheritance of `Virtus::Attribute`
1. Rename `coerce` to `self.parse`
1. Rename `value_coerced?` to `self.parsed?`

The custom type must have a class-level `parse` method to the model. A class-level `parsed?` is needed if the parsed type differs from the defined type. In the example below, since `SecureUri` is not the same as `URI::HTTPS`, `self.parsed?` is needed:

```ruby
# New dry-types parser
class SecureUri
  def self.parse(value)
    URI.parse value
  end

  def self.parsed?(value)
    value.is_a? URI::HTTPS
  end
end

params do
  requires :secure_uri, type: SecureUri
end
```

#### Coercing to `FalseClass` or `TrueClass` no longer works

Previous Grape versions allowed this, though it wasn't documented:

```ruby
requires :true_value, type: TrueClass
requires :bool_value, types: [FalseClass, TrueClass]
```

This is no longer supported, if you do this, your values will never be valid. Instead you should do this:

```ruby
requires :true_value, type: Boolean # in your endpoint you should validate if this is actually `true`
requires :bool_value, type: Boolean
```

#### Ensure that Array types have explicit coercions

Unlike Virtus, dry-types does not perform any implict coercions. If you have any uses of `Array[String]`, `Array[Integer]`, etc. be sure they use a `coerce_with` block. For example:

```ruby
requires :values, type: Array[String]
```

It's quite common to pass a comma-separated list, such as `tag1,tag2` as `values`. Previously Virtus would implicitly coerce this to `Array(values)` so that `["tag1,tag2"]` would pass the type checks, but with `dry-types` the values are no longer coerced for you. To fix this, you might do:

```ruby
requires :values, type: Array[String], coerce_with: ->(val) { val.split(',').map(&:strip) }
```

Likewise, for `Array[Integer]`, you might do:

```ruby
requires :values, type: Array[Integer], coerce_with: ->(val) { val.split(',').map(&:strip).map(&:to_i) }
```

For more information see [#1920](https://github.com/ruby-grape/grape/pull/1920).

### Upgrading to >= 1.2.4

#### Headers in `error!` call

Headers in `error!` will be merged with `headers` hash. If any header need to be cleared on `error!` call, make sure to move it to the `after` block.

```ruby
class SampleApi < Grape::API
  before do
    header 'X-Before-Header', 'before_call'
  end

  get 'ping' do
    header 'X-App-Header', 'on_call'
    error! :pong, 400, 'X-Error-Details' => 'Invalid token'
  end
end
```
**Former behaviour**
```ruby
  response.headers['X-Before-Header'] # => nil
  response.headers['X-App-Header'] # => nil
  response.headers['X-Error-Details'] # => Invalid token
```

**Current behaviour**
```ruby
  response.headers['X-Before-Header'] # => 'before_call'
  response.headers['X-App-Header'] # => 'on_call'
  response.headers['X-Error-Details'] # => Invalid token
```

### Upgrading to >= 1.2.1

#### Obtaining the name of a mounted class

In order to make obtaining the name of a mounted class simpler, we've delegated `.to_s` to `base.name`

**Deprecated in 1.2.0**
```ruby
  payload[:endpoint].options[:for].name
```
**New**
```ruby
  payload[:endpoint].options[:for].to_s
```

### Upgrading to >= 1.2.0

#### Changes in the Grape::API class

##### Patching the class

In an effort to make APIs re-mountable, The class `Grape::API` no longer refers to an API instance, rather, what used to be `Grape::API` is now `Grape::API::Instance` and `Grape::API` was replaced with a class that can contain several instances of `Grape::API`.

This changes were done in such a way that no code-changes should be required. However, if experiencing problems, or relying on private methods and internal behaviour too deeply, it is possible to restore the prior behaviour by replacing the references from `Grape::API` to `Grape::API::Instance`.

Note, this is particularly relevant if you are opening the class `Grape::API` for modification.

**Deprecated**
```ruby
class Grape::API
  # your patched logic
  ...
end
```
**New**
```ruby
class Grape::API::Instance
  # your patched logic
  ...
end
```

##### `name` (and other caveats) of the mounted API

After the patch, the mounted API is no longer a Named class inheriting from `Grape::API`, it is an anonymous class which inherit from `Grape::API::Instance`.

What this means in practice, is:

- Generally: you can access the named class from the instance calling the getter `base`.
- In particular: If you need the `name`, you can use `base`.`name`.

**Deprecated**

```ruby
  payload[:endpoint].options[:for].name
```

**New**

```ruby
  payload[:endpoint].options[:for].base.name
```

#### Changes in rescue_from returned object

Grape will now check the object returned from `rescue_from` and ensure that it is a `Rack::Response`. That makes sure response is valid and avoids exposing service information. Change any code that invoked `Rack::Response.new(...).finish` in a custom `rescue_from` block to `Rack::Response.new(...)` to comply with the validation.

```ruby
class Twitter::API < Grape::API
  rescue_from :all do |e|
    # version prior to 1.2.0
    Rack::Response.new([ e.message ], 500, { 'Content-type' => 'text/error' }).finish
    # 1.2.0  version
    Rack::Response.new([ e.message ], 500, { 'Content-type' => 'text/error' })
  end
end
```

See [#1757](https://github.com/ruby-grape/grape/pull/1757) and [#1776](https://github.com/ruby-grape/grape/pull/1776) for more information.

### Upgrading to >= 1.1.0

#### Changes in HTTP Response Code for Unsupported Content Type

For PUT, POST, PATCH, and DELETE requests where a non-empty body and a "Content-Type" header is supplied that is not supported by the Grape API, Grape will no longer return a 406 "Not Acceptable" HTTP status code and will instead return a 415 "Unsupported Media Type" so that the usage of HTTP status code falls more in line with the specification of [RFC 2616](https://www.ietf.org/rfc/rfc2616.txt).

### Upgrading to >= 1.0.0

#### Changes in XML and JSON Parsers

Grape no longer uses `multi_json` or `multi_xml` by default and uses `JSON` and `ActiveSupport::XmlMini` instead. This has no visible impact on JSON processing, but the default behavior of the XML parser has changed. For example, an XML POST containing `<user>Bobby T.</user>` was parsed as `Bobby T.` with `multi_xml`, and as now parsed as `{"__content__"=>"Bobby T."}` with `XmlMini`.

If you were using `MultiJson.load`, `MultiJson.dump` or `MultiXml.parse`, you can substitute those with `Grape::Json.load`, `Grape::Json.dump`, `::Grape::Xml.parse`, or directly with `JSON.load`, `JSON.dump`, `XmlMini.parse`, etc.

To restore previous behavior, add `multi_json` or `multi_xml` to your `Gemfile` and `require` it.

See [#1623](https://github.com/ruby-grape/grape/pull/1623) for more information.

#### Changes in Parameter Class

The default class for `params` has changed from `Hashie::Mash` to `ActiveSupport::HashWithIndifferentAccess` and the `hashie` dependency has been removed. This means that by default you can no longer access parameters by method name.

```ruby
class API < Grape::API
  params do
    optional :color, type: String
  end
  get do
    params[:color] # use params[:color] instead of params.color
  end
end
```

To restore the behavior of prior versions, add `hashie` to your `Gemfile` and `include Grape::Extensions::Hashie::Mash::ParamBuilder` in your API.

```ruby
class API < Grape::API
  include Grape::Extensions::Hashie::Mash::ParamBuilder

  params do
    optional :color, type: String
  end
  get do
    # params.color works
  end
end
```

This behavior can also be overridden on individual parameter blocks using `build_with`.

```ruby
params do
  build_with Grape::Extensions::Hash::ParamBuilder
  optional :color, type: String
end
```

If you're constructing your own `Grape::Request` in a middleware, you can pass different parameter handlers to create the desired `params` class with `build_params_with`.

```ruby
def request
  Grape::Request.new(env, build_params_with: Grape::Extensions::Hashie::Mash::ParamBuilder)
end
```

See [#1610](https://github.com/ruby-grape/grape/pull/1610) for more information.

#### The `except`, `except_message`, and `proc` options of the `values` validator are deprecated.

The new `except_values` validator should be used in place of the `except` and `except_message` options of the `values` validator.

Arity one Procs may now be used directly as the `values` option to explicitly test param values.

**Deprecated**
```ruby
params do
  requires :a, values: { value: 0..99, except: [3] }
  requires :b, values: { value: 0..99, except: [3], except_message: 'not allowed' }
  requires :c, values: { except: ['admin'] }
  requires :d, values: { proc: -> (v) { v.even? } }
end
```
**New**
```ruby
params do
  requires :a, values: 0..99, except_values: [3]
  requires :b, values: 0..99, except_values: { value: [3], message: 'not allowed' }
  requires :c, except_values: ['admin']
  requires :d, values: -> (v) { v.even? }
end
```

See [#1616](https://github.com/ruby-grape/grape/pull/1616) for more information.

### Upgrading to >= 0.19.1

#### DELETE now defaults to status code 200 for responses with a body, or 204 otherwise

Prior to this version, DELETE requests defaulted to a status code of 204 No Content, even when the response included content. This behavior confused some clients and prevented the formatter middleware from running properly. As of this version, DELETE requests will only default to a 204 No Content status code if no response body is provided, and will default to 200 OK otherwise.

Specifically, DELETE behaviour has changed as follows:

- In versions < 0.19.0, all DELETE requests defaulted to a 200 OK status code.
- In version 0.19.0, all DELETE requests defaulted to a 204 No Content status code, even when content was included in the response.
- As of version 0.19.1, DELETE requests default to a 204 No Content status code, unless content is supplied, in which case they default to a 200 OK status code.

To achieve the old behavior, one can specify the status code explicitly:

```ruby
delete :id do
  status 204 # or 200, for < 0.19.0 behavior
  'foo successfully deleted'
end
```

One can also use the new `return_no_content` helper to explicitly return a 204 status code and an empty body for any request type:

```ruby
delete :id do
  return_no_content
  'this will not be returned'
end
```

See [#1550](https://github.com/ruby-grape/grape/pull/1550) for more information.

### Upgrading to >= 0.18.1

#### Changes in priority of :any routes

Prior to this version, `:any` routes were searched after matching first route and 405 routes. This behavior has changed and `:any` routes are now searched before 405 processing. In the following example the `:any` route will match first when making a request with an unsupported verb.

```ruby
post :example do
  'example'
end
route :any, '*path' do
  error! :not_found, 404
end

get '/example' #=> before: 405, after: 404
```

#### Removed param processing from built-in OPTIONS handler

When a request is made to the built-in `OPTIONS` handler, only the `before` and `after` callbacks associated with the resource will be run.  The `before_validation` and `after_validation` callbacks and parameter validations will be skipped.

See [#1505](https://github.com/ruby-grape/grape/pull/1505) for more information.

#### Changed endpoint params validation

Grape now correctly returns validation errors for all params when multiple params are passed to a requires.
The following code will return `one is missing, two is missing` when calling the endpoint without parameters.

```ruby
params do
  requires :one, :two
end
```

Prior to this version the response would be `one is missing`.

See [#1510](https://github.com/ruby-grape/grape/pull/1510) for more information.

#### The default status code for DELETE is now 204 instead of 200.

Breaking change: Sets the default response status code for a delete request to 204. A status of 204 makes the response more distinguishable and therefore easier to handle on the client side, particularly because a DELETE request typically returns an empty body as the resource was deleted or voided.

To achieve the old behavior, one has to set it explicitly:
```ruby
delete :id do
  status 200
  'foo successfully deleted'
end
```

For more information see: [#1532](https://github.com/ruby-grape/grape/pull/1532).

### Upgrading to >= 0.17.0

#### Removed official support for Ruby < 2.2.2

Grape is no longer automatically tested against versions of Ruby prior to 2.2.2. This is because of its dependency on activesupport which, with version 5.0.0, now requires at least Ruby 2.2.2.

See [#1441](https://github.com/ruby-grape/grape/pull/1441) for nmore information.

#### Changed priority of `rescue_from` clauses applying

The `rescue_from` clauses declared inside a namespace would take a priority over ones declared in the root scope.
This could possibly affect those users who use different `rescue_from` clauses in root scope and in namespaces.

See [#1405](https://github.com/ruby-grape/grape/pull/1405) for more information.

#### Helper methods injected inside `rescue_from` in middleware

Helper methods are injected inside `rescue_from` may cause undesirable effects. For example, definining a helper method called `error!` will take precendence over the built-in `error!` method and should be renamed.

See [#1451](https://github.com/ruby-grape/grape/issues/1451) for an example.

### Upgrading to >= 0.16.0

#### Replace rack-mount with new router

The `Route#route_xyz` methods have been deprecated since 0.15.1.

Please use `Route#xyz` instead.

Note that the `Route#route_method` was replaced by `Route#request_method`.

The following code would work correctly.

```ruby
TwitterAPI::versions # yields [ 'v1', 'v2' ]
TwitterAPI::routes # yields an array of Grape::Route objects
TwitterAPI::routes[0].version # => 'v1'
TwitterAPI::routes[0].description # => 'Includes custom settings.'
TwitterAPI::routes[0].settings[:custom] # => { key: 'value' }

TwitterAPI::routes[0].request_method # => 'GET'
```

#### `file` method accepts path to file

Now to serve files via Grape just pass the path to the file. Functionality with FileStreamer-like objects is deprecated.

Please, replace your FileStreamer-like objects with paths of served files.

Old style:

```ruby
class FileStreamer
  def initialize(file_path)
    @file_path = file_path
  end

  def each(&blk)
    File.open(@file_path, 'rb') do |file|
      file.each(10, &blk)
    end
  end
end

# ...

class API < Grape::API
  get '/' do
    file FileStreamer.new('/path/to/file')
  end
end
```

New style:

```ruby
class API < Grape::API
  get '/' do
    file '/path/to/file'
  end
end
```

### Upgrading to >= 0.15.0

#### Changes to availability of `:with` option of `rescue_from` method

The `:with` option of `rescue_from` does not accept value except Proc, String or Symbol now.

If you have been depending the old behavior, you should use lambda block instead.

```ruby
class API < Grape::API
  rescue_from :all, with: -> { Rack::Response.new('rescued with a method', 400) }
end
```

#### Changes to behavior of `after` method of middleware on error

The `after` method of the middleware is now also called on error. The following code would work correctly.

```ruby
class ErrorMiddleware < Grape::Middleware::Base
  def after
    return unless @app_response && @app_response[0] == 500
    env['rack.logger'].debug("Raised error on #{env['PATH_INFO']}")
  end
end
```

See [#1147](https://github.com/ruby-grape/grape/issues/1147) and [#1240](https://github.com/ruby-grape/grape/issues/1240) for discussion of the issues.

A warning will be logged if an exception is raised in an `after` callback, which points you to middleware that was not called in the previous version and is called now.

```
caught error of type NoMethodError in after callback inside Api::Middleware::SomeMiddleware : undefined method `headers' for nil:NilClass
```

See [#1285](https://github.com/ruby-grape/grape/pull/1285) for more information.

#### Changes to Method Not Allowed routes

A `405 Method Not Allowed` error now causes `Grape::Exceptions::MethodNotAllowed` to be raised, which will be rescued via `rescue_from :all`. Restore old behavior with the following error handler.

```ruby
rescue_from Grape::Exceptions::MethodNotAllowed do |e|
  error! e.message, e.status, e.headers
end
```

See [#1283](https://github.com/ruby-grape/grape/pull/1283) for more information.

#### Changes to Grape::Exceptions::Validation parameters

When raising `Grape::Exceptions::Validation` explicitly, replace `message_key` with `message`.

For example,

```ruby
fail Grape::Exceptions::Validation, params: [:oauth_token_secret], message_key: :presence
```

becomes

```ruby
fail Grape::Exceptions::Validation, params: [:oauth_token_secret], message: :presence
```

See [#1295](https://github.com/ruby-grape/grape/pull/1295) for more information.

### Upgrading to >= 0.14.0

#### Changes to availability of DSL methods in filters

The `#declared` method of the route DSL is no longer available in the `before` filter.  Using `declared` in a `before` filter will now raise `Grape::DSL::InsideRoute::MethodNotYetAvailable`.

See [#1074](https://github.com/ruby-grape/grape/issues/1074) for discussion of the issue.

#### Changes to header versioning and invalid header version handling

Identical endpoints with different versions now work correctly. A regression introduced in Grape 0.11.0 caused all but the first-mounted version for such an endpoint to wrongly throw an `InvalidAcceptHeader`. As a side effect, requests with a correct vendor but invalid version can no longer be rescued from a `rescue_from` block.

See [#1114](https://github.com/ruby-grape/grape/pull/1114) for more information.

#### Bypasses formatters when status code indicates no content

To be consistent with rack and it's handling of standard responses associated with no content, both default and custom formatters will now be bypassed when processing responses for status codes defined [by rack](https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L567)

See [#1190](https://github.com/ruby-grape/grape/pull/1190) for more information.

#### Redirects respond as plain text with message

`#redirect` now uses `text/plain` regardless of whether that format has been enabled. This prevents formatters from attempting to serialize the message body and allows for a descriptive message body to be provided - and optionally overridden - that better fulfills the theme of the HTTP spec.

See [#1194](https://github.com/ruby-grape/grape/pull/1194) for more information.

### Upgrading to >= 0.12.0

#### Changes in middleware

The Rack response object is no longer converted to an array by the formatter, enabling streaming. If your custom middleware is accessing `@app_response`, update it to expect a `Rack::Response` instance instead of an array.

For example,

```ruby
class CacheBusterMiddleware < Grape::Middleware::Base
  def after
    @app_response[1]['Expires'] = Time.at(0).utc.to_s
    @app_response
  end
end
```

becomes

```ruby
class CacheBusterMiddleware < Grape::Middleware::Base
  def after
    @app_response.headers['Expires'] = Time.at(0).utc.to_s
    @app_response
  end
end
```

See [#1029](https://github.com/ruby-grape/grape/pull/1029) for more information.

There is a known issue because of this change. When Grape is used with an older than 1.2.4 version of [warden](https://github.com/hassox/warden) there may be raised the following exception having the [rack-mount](https://github.com/jm/rack-mount) gem's lines as last ones in the backtrace:

```
NoMethodError: undefined method `[]' for nil:NilClass
```

The issue can be solved by upgrading warden to 1.2.4 version.

See [#1151](https://github.com/ruby-grape/grape/issues/1151) for more information.

#### Changes in present

Using `present` with objects that responded to `merge` would cause early evaluation of the represented object, with unexpected side-effects, such as missing parameters or environment within rendering code. Grape now only merges represented objects with a previously rendered body, usually when multiple `present` calls are made in the same route.

See [grape-with-roar#5](https://github.com/dblock/grape-with-roar/issues/5) and [#1023](https://github.com/ruby-grape/grape/issues/1023).

#### Changes to regexp validator

Parameters with `nil` value will now pass `regexp` validation. To disallow `nil` value for an endpoint, add `allow_blank: false`.

```ruby
params do
  requires :email, allow_blank: false, regexp: /.+@.+/
end
```

See [#957](https://github.com/ruby-grape/grape/pull/957) for more information.

#### Replace error_response with error! in rescue_from blocks

Note: `error_response` is being deprecated, not removed.

```ruby
def error!(message, status = options[:default_status], headers = {}, backtrace = [])
  headers = { 'Content-Type' => content_type }.merge(headers)
  rack_response(format_message(message, backtrace), status, headers)
end
```

For example,

```
error_response({ message: { message: 'No such page.', id: 'missing_page' }, status: 404, headers: { 'Content-Type' => 'api/error' })
```

becomes

```
error!({ message: 'No such page.', id: 'missing_page' }, 404, { 'Content-Type' => 'api/error' })
```

`error!` also supports just passing a message. `error!('Server error.')` and `format: :json` returns the following JSON response

```
{ 'error': 'Server error.' }
```

with a status code of 500 and a Content Type of text/error.

Optionally, also replace `Rack::Response.new` with `error!.`
The following are equivalent:

```
Rack::Response.new([ e.message ], 500, { "Content-type" => "text/error" }).finish
error!(e)
```

See [#889](https://github.com/ruby-grape/grape/issues/889) for more information.

#### Changes to routes when using `format`

Version 0.10.0 has introduced a change via [#809](https://github.com/ruby-grape/grape/pull/809) whereas routes no longer got file-type suffixes added if you declared a single API `format`. This has been reverted, it's now again possible to call API with proper suffix when single `format` is defined:

```ruby
class API < Grape::API
  format :json

  get :hello do
    { hello: 'world' }
  end
end
```

Will respond with JSON to `/hello` **and** `/hello.json`.

Will respond with 404 to `/hello.xml`, `/hello.txt` etc.

See the [#1001](https://github.com/ruby-grape/grape/pull/1001) and [#914](https://github.com/ruby-grape/grape/issues/914) for more info.

### Upgrading to >= 0.11.0

#### Added Rack 1.6.0 support

Grape now supports, but doesn't require Rack 1.6.0. If you encounter an issue with parsing requests larger than 128KB, explictly require Rack 1.6.0 in your Gemfile.

```ruby
gem 'rack', '~> 1.6.0'
```

See [#559](https://github.com/ruby-grape/grape/issues/559) for more information.

#### Removed route_info

Key route_info is excluded from params.

See [#879](https://github.com/ruby-grape/grape/pull/879) for more information.


#### Fix callbacks within a version block

Callbacks defined in a version block are only called for the routes defined in that block. This was a regression introduced in Grape 0.10.0, and is fixed in this version.

See [#901](https://github.com/ruby-grape/grape/pull/901) for more information.


#### Make type of group of parameters required

Groups of parameters now require their type to be set explicitly as Array or Hash.
Not setting the type now results in MissingGroupTypeError, unsupported type will raise UnsupportedTypeError.

See [#886](https://github.com/ruby-grape/grape/pull/886) for more information.

### Upgrading to >= 0.10.1

#### Changes to `declared(params, include_missing: false)`

Attributes with `nil` values or with values that evaluate to `false` are no longer considered *missing* and will be returned when `include_missing` is set to `false`.

See [#864](https://github.com/ruby-grape/grape/pull/864) for more information.

### Upgrading to >= 0.10.0

#### Changes to content-types

The following content-types have been removed:

* atom (application/atom+xml)
* rss (application/rss+xml)
* jsonapi (application/jsonapi)

This is because they have never been properly supported.

#### Changes to desc

New block syntax:

Former:

```ruby
  desc "some descs",
    detail: 'more details',
    entity: API::Entities::Entity,
    params: API::Entities::Status.documentation,
    named: 'a name',
    headers: [XAuthToken: {
      description: 'Valdates your identity',
      required: true
    }
  get nil, http_codes: [
    [401, 'Unauthorized', API::Entities::BaseError],
    [404, 'not found', API::Entities::Error]
  ] do
```

Now:

```ruby
desc "some descs" do
  detail 'more details'
  params API::Entities::Status.documentation
  success API::Entities::Entity
  failure [
    [401, 'Unauthorized', API::Entities::BaseError],
    [404, 'not found', API::Entities::Error]
  ]
  named 'a name'
  headers [
    XAuthToken: {
      description: 'Valdates your identity',
      required: true
    },
    XOptionalHeader: {
      description: 'Not really needed',
      required: false
    }
  ]
end
```

#### Changes to Route Options and Descriptions

A common hack to extend Grape with custom DSL methods was manipulating `@last_description`.

``` ruby
module Grape
  module Extensions
    module SortExtension
      def sort(value)
        @last_description ||= {}
        @last_description[:sort] ||= {}
        @last_description[:sort].merge! value
        value
      end
    end

    Grape::API.extend self
  end
end
```

You could access this value from within the API with `route.route_sort` or, more generally, via `env['api.endpoint'].options[:route_options][:sort]`.

This will no longer work, use the documented and supported `route_setting`.

``` ruby
module Grape
  module Extensions
    module SortExtension
      def sort(value)
        route_setting :sort, sort: value
        value
      end
    end

    Grape::API.extend self
  end
end
```

To retrieve this value at runtime from within an API, use `env['api.endpoint'].route_setting(:sort)` and when introspecting a mounted API, use `route.route_settings[:sort]`.

#### Accessing Class Variables from Helpers

It used to be possible to fetch an API class variable from a helper function. For example:

```ruby
@@static_variable = 42

helpers do
  def get_static_variable
    @@static_variable
  end
end

get do
  get_static_variable
end
```

This will no longer work. Use a class method instead of a helper.

```ruby
@@static_variable = 42

def self.get_static_variable
  @@static_variable
end

get do
  get_static_variable
end
```

For more information see [#836](https://github.com/ruby-grape/grape/issues/836).

#### Changes to Custom Validators

To implement a custom validator, you need to inherit from `Grape::Validations::Base` instead of `Grape::Validations::Validator`.

For more information see [Custom Validators](https://github.com/ruby-grape/grape#custom-validators) in the documentation.

#### Changes to Raising Grape::Exceptions::Validation

In previous versions raising `Grape::Exceptions::Validation` required a single `param`.

```ruby
raise Grape::Exceptions::Validation, param: :id, message_key: :presence
```

The `param` argument has been deprecated and is now an array of `params`, accepting multiple values.

```ruby
raise Grape::Exceptions::Validation, params: [:id], message_key: :presence
```

#### Changes to routes when using `format`

Routes will no longer get file-type suffixes added if you declare a single API `format`. For example,

```ruby
class API < Grape::API
  format :json

  get :hello do
    { hello: 'world' }
  end
end
```

Pre-0.10.0, this would respond with JSON to `/hello`, `/hello.json`, `/hello.xml`, `/hello.txt`, etc.

Now, this will only respond with JSON to `/hello`, but will be a 404 when trying to access `/hello.json`, `/hello.xml`, `/hello.txt`, etc.

If you declare further `content_type`s, this behavior will be circumvented. For example, the following API will respond with JSON to `/hello`, `/hello.json`, `/hello.xml`, `/hello.txt`, etc.

```ruby
class API < Grape::API
  format :json
  content_type :json, 'application/json'

  get :hello do
    { hello: 'world' }
  end
end
```

See the [the updated API Formats documentation](https://github.com/ruby-grape/grape#api-formats) and [#809](https://github.com/ruby-grape/grape/pull/809) for more info.

#### Changes to Evaluation of Permitted Parameter Values

Permitted and default parameter values are now only evaluated lazily for each request when declared as a proc. The following code would raise an error at startup time.

```ruby
params do
  optional :v, values: -> { [:x, :y] }, default: -> { :z }
end
```

Remove the proc to get the previous behavior.

```ruby
params do
  optional :v, values: [:x, :y], default: :z
end
```

See [#801](https://github.com/ruby-grape/grape/issues/801) for more information.

#### Changes to version

If version is used with a block, the callbacks defined within that version block are not scoped to that individual block. In other words, the callback would be inherited by all versions blocks that follow the first one e.g

```ruby
class API < Grape::API
  resource :foo do
    version 'v1', :using => :path do
      before do
        @output ||= 'hello1'
      end
      get '/' do
        @output += '-v1'
      end
    end

    version 'v2', :using => :path do
      before do
        @output ||= 'hello2'
      end
      get '/:id' do
        @output += '-v2'
      end
    end
  end
end
```

when making a API call `GET /foo/v2/1`, the API would set instance variable `@output` to `hello1-v2`

See [#898](https://github.com/ruby-grape/grape/issues/898) for more information.


### Upgrading to >= 0.9.0

#### Changes in Authentication

The following middleware classes have been removed:

* `Grape::Middleware::Auth::Basic`
* `Grape::Middleware::Auth::Digest`
* `Grape::Middleware::Auth::OAuth2`

When you use theses classes directly like:

```ruby
 module API
   class Root < Grape::API
     class Protected < Grape::API
       use Grape::Middleware::Auth::OAuth2,
           token_class: 'AccessToken',
           parameter: %w(access_token api_key)

```

you have to replace these classes.

As replacement can be used

* `Grape::Middleware::Auth::Basic`  => [`Rack::Auth::Basic`](https://github.com/rack/rack/blob/master/lib/rack/auth/basic.rb)
* `Grape::Middleware::Auth::Digest` => [`Rack::Auth::Digest::MD5`](https://github.com/rack/rack/blob/master/lib/rack/auth/digest/md5.rb)
* `Grape::Middleware::Auth::OAuth2` => [warden-oauth2](https://github.com/opperator/warden-oauth2) or [rack-oauth2](https://github.com/nov/rack-oauth2)

If this is not possible you can extract the middleware files from [grape v0.7.0](https://github.com/ruby-grape/grape/tree/v0.7.0/lib/grape/middleware/auth) and host these files within your application

See [#703](https://github.com/ruby-grape/Grape/pull/703) for more information.

### Upgrading to >= 0.7.0

#### Changes in Exception Handling

Assume you have the following exception classes defined.

```ruby
class ParentError < StandardError; end
class ChildError < ParentError; end
```

In Grape <= 0.6.1, the `rescue_from` keyword only handled the exact exception being raised. The following code would rescue `ParentError`, but not `ChildError`.

```ruby
rescue_from ParentError do |e|
  # only rescue ParentError
end
```

This made it impossible to rescue an exception hieararchy, which is a more sensible default. In Grape 0.7.0 or newer, both `ParentError` and `ChildError` are rescued.

```ruby
rescue_from ParentError do |e|
  # rescue both ParentError and ChildError
end
```

To only rescue the base exception class, set `rescue_subclasses: false`.

```ruby
rescue_from ParentError, rescue_subclasses: false do |e|
  # only rescue ParentError
end
```

See [#544](https://github.com/ruby-grape/grape/pull/544) for more information.


#### Changes in the Default HTTP Status Code

In Grape <= 0.6.1, the default status code returned from `error!` was 403.

```ruby
error! "You may not reticulate this spline!" # yields HTTP error 403
```

This was a bad default value, since 403 means "Forbidden". Change any call to `error!` that does not specify a status code to specify one. The new default value is a more sensible default of 500, which is "Internal Server Error".

```ruby
error! "You may not reticulate this spline!", 403 # yields HTTP error 403
```

You may also use `default_error_status` to change the global default.

```ruby
default_error_status 400
```

See [#525](https://github.com/ruby-grape/Grape/pull/525) for more information.


#### Changes in Parameter Declaration and Validation

In Grape <= 0.6.1, `group`, `optional` and `requires` keywords with a block accepted either an `Array` or a `Hash`.

```ruby
params do
  requires :id, type: Integer
  group :name do
    requires :first_name
    requires :last_name
  end
end
```

This caused the ambiguity and unexpected errors described in [#543](https://github.com/ruby-grape/Grape/issues/543).

In Grape 0.7.0, the `group`, `optional` and `requires` keywords take an additional `type` attribute which defaults to `Array`. This means that without a `type` attribute, these nested parameters will no longer accept a single hash, only an array (of hashes).

Whereas in 0.6.1 the API above accepted the following json, it no longer does in 0.7.0.

```json
{
  "id": 1,
  "name": {
    "first_name": "John",
    "last_name" : "Doe"
  }
}
```

The `params` block should now read as follows.

```ruby
params do
  requires :id, type: Integer
  requires :name, type: Hash do
    requires :first_name
    requires :last_name
  end
end
```

See [#545](https://github.com/ruby-grape/Grape/pull/545) for more information.


### Upgrading to 0.6.0

In Grape <= 0.5.0, only the first validation error was raised and processing aborted. Validation errors are now collected and a single `Grape::Exceptions::ValidationErrors` exception is raised. You can access the collection of validation errors as `.errors`.

```ruby
rescue_from Grape::Exceptions::Validations do |e|
  Rack::Response.new({
    status: 422,
    message: e.message,
    errors: e.errors
  }.to_json, 422)
end
```

For more information see [#462](https://github.com/ruby-grape/grape/issues/462).
