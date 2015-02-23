Upgrading Grape
===============

### Upgrading to >= 0.11.0

#### Added Rack 1.6.0 Support

Grape now supports, but doesn't require Rack 1.6.0. If you encounter an issue with parsing requests larger than 128KB, explictly require Rack 1.6.0 in your Gemfile.

```ruby
gem 'rack', '~> 1.6.0'
```

See [#559](https://github.com/intridea/grape/issues/559) for more information.

#### Removed route_info

Key route_info is excluded from params.

See [#879](https://github.com/intridea/grape/pull/879) for more information.


#### Fix callbacks within a version block

Callbacks defined in a version block are only called for the routes defined in that block. This was a regression introduced in Grape 0.10.0, and is fixed in this version.

See [#901](https://github.com/intridea/grape/pull/901) for more information.


#### Make type of group of parameters required

Groups of parameters now require their type to be set explicitly as Array or Hash.
Not setting the type now results in MissingGroupTypeError, unsupported type will raise UnsupportedTypeError.

See [#886](https://github.com/intridea/grape/pull/886) for more information.

### Upgrading to >= 0.10.1

#### Changes to `declared(params, include_missing: false)`

Attributes with `nil` values or with values that evaluate to `false` are no longer considered *missing* and will be returned when `include_missing` is set to `false`.

See [#864](https://github.com/intridea/grape/pull/864) for more information.

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

For more information see [#836](https://github.com/intridea/grape/issues/836).

#### Changes to Custom Validators

To implement a custom validator, you need to inherit from `Grape::Validations::Base` instead of `Grape::Validations::Validator`.

For more information see [Custom Validators](https://github.com/intridea/grape#custom-validators) in the documentation.

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

See the [the updated API Formats documentation](https://github.com/intridea/grape#api-formats) and [#809](https://github.com/intridea/grape/pull/809) for more info.

#### Changes to Evaluation of Permitted Parameter Values

Permitted and default parameter values are now only evaluated lazily for each request when declared as a proc. The following code would raise an error at startup time.

```ruby
params do
  optional :v, values: -> { [:x, :y] }, default: -> { :z } }
end
```

Remove the proc to get the previous behavior.

```ruby
params do
  optional :v, values: [:x, :y], default: :z }
end
```

See [#801](https://github.com/intridea/grape/issues/801) for more information.

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

See [#898](https://github.com/intridea/grape/issues/898) for more information.


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

If this is not possible you can extract the middleware files from [grape v0.7.0](https://github.com/intridea/grape/tree/v0.7.0/lib/grape/middleware/auth)
and host these files within your application

See [#703](https://github.com/intridea/Grape/pull/703) for more information.

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

See [#544](https://github.com/intridea/grape/pull/544) for more information.


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

See [#525](https://github.com/intridea/Grape/pull/525) for more information.


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

This caused the ambiguity and unexpected errors described in [#543](https://github.com/intridea/Grape/issues/543).

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

See [#545](https://github.com/intridea/Grape/pull/545) for more information.


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

For more information see [#462](https://github.com/intridea/grape/issues/462).
