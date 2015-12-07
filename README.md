![grape logo](grape.png)

[![Gem Version](https://badge.fury.io/rb/grape.svg)](http://badge.fury.io/rb/grape)
[![Build Status](https://travis-ci.org/ruby-grape/grape.svg?branch=master)](https://travis-ci.org/ruby-grape/grape)
[![Dependency Status](https://gemnasium.com/ruby-grape/grape.svg)](https://gemnasium.com/ruby-grape/grape)
[![Code Climate](https://codeclimate.com/github/ruby-grape/grape.svg)](https://codeclimate.com/github/ruby-grape/grape)
[![Inline docs](http://inch-ci.org/github/ruby-grape/grape.svg)](http://inch-ci.org/github/ruby-grape/grape)

## Table of Contents

- [What is Grape?](#what-is-grape)
- [Stable Release](#stable-release)
- [Project Resources](#project-resources)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Mounting](#mounting)
  - [Rack](#rack)
  - [ActiveRecord without Rails](#activerecord-without-rails)
  - [Alongside Sinatra (or other frameworks)](#alongside-sinatra-or-other-frameworks)
  - [Rails](#rails)
  - [Modules](#modules)
- [Versioning](#versioning)
  - [Path](#path)
  - [Header](#header)
  - [Accept-Version Header](#accept-version-header)
  - [Param](#param)
- [Describing Methods](#describing-methods)
- [Parameters](#parameters)
  - [Declared](#declared)
  - [Include Missing](#include-missing)
- [Parameter Validation and Coercion](#parameter-validation-and-coercion)
  - [Supported Parameter Types](#supported-parameter-types)
  - [Custom Types and Coercions](#custom-types-and-coercions)
  - [Multipart File Parameters](#multipart-file-parameters)
  - [First-Class `JSON` Types](#first-class-json-types)
  - [Multiple Allowed Types](#multiple-allowed-types)
  - [Validation of Nested Parameters](#validation-of-nested-parameters)
  - [Dependent Parameters](#dependent-parameters)
  - [Built-in Validators](#built-in-validators)
  - [Namespace Validation and Coercion](#namespace-validation-and-coercion)
  - [Custom Validators](#custom-validators)
  - [Validation Errors](#validation-errors)
  - [I18n](#i18n)
- [Headers](#headers)
- [Routes](#routes)
- [Helpers](#helpers)
- [Path Helpers](#path-helpers)
- [Parameter Documentation](#parameter-documentation)
- [Cookies](#cookies)
- [HTTP Status Code](#http-status-code)
- [Redirecting](#redirecting)
- [Allowed Methods](#allowed-methods)
- [Raising Exceptions](#raising-exceptions)
  - [Default Error HTTP Status Code](#default-error-http-status-code)
  - [Handling 404](#handling-404)
- [Exception Handling](#exception-handling)
  - [Rails 3.x](#rails-3x)
- [Logging](#logging)
- [API Formats](#api-formats)
  - [JSONP](#jsonp)
  - [CORS](#cors)
- [Content-type](#content-type)
- [API Data Formats](#api-data-formats)
- [RESTful Model Representations](#restful-model-representations)
  - [Grape Entities](#grape-entities)
  - [Hypermedia and Roar](#hypermedia-and-roar)
  - [Rabl](#rabl)
  - [Active Model Serializers](#active-model-serializers)
- [Sending Raw or No Data](#sending-raw-or-no-data)
- [Authentication](#authentication)
- [Describing and Inspecting an API](#describing-and-inspecting-an-api)
- [Current Route and Endpoint](#current-route-and-endpoint)
- [Before and After](#before-and-after)
- [Anchoring](#anchoring)
- [Using Custom Middleware](#using-custom-middleware)
  - [Rails Middleware](#rails-middleware)
  - [Remote IP](#remote-ip)
- [Writing Tests](#writing-tests)
  - [Writing Tests with Rack](#writing-tests-with-rack)
  - [Writing Tests with Rails](#writing-tests-with-rails)
  - [Stubbing Helpers](#stubbing-helpers)
- [Reloading API Changes in Development](#reloading-api-changes-in-development)
  - [Reloading in Rack Applications](#reloading-in-rack-applications)
  - [Reloading in Rails Applications](#reloading-in-rails-applications)
- [Performance Monitoring](#performance-monitoring)
  - [Active Support Instrumentation](#active-support-instrumentation)
  - [Monitoring Products](#monitoring-products)
- [Contributing to Grape](#contributing-to-grape)
- [License](#license)
- [Copyright](#copyright)

## What is Grape?

Grape is a REST-like API micro-framework for Ruby. It's designed to run on Rack
or complement existing web application frameworks such as Rails and Sinatra by
providing a simple DSL to easily develop RESTful APIs. It has built-in support
for common conventions, including multiple formats, subdomain/prefix restriction,
content negotiation, versioning and much more.

## Stable Release

You're reading the documentation for the stable release of Grae [0.14.0](https://github.com/ruby-grape/grape/blob/v0.14.0/README.md).
Please read [UPGRADING](UPGRADING.md) when upgrading from a previous version.

## Project Resources

* [Grape Website](http://www.ruby-grape.org)
* Need help? [Grape Google Group](http://groups.google.com/group/ruby-grape)

## Installation

Grape is available as a gem, to install it just install the gem:

    gem install grape

If you're using Bundler, add the gem to Gemfile.

    gem 'grape'

Run `bundle install`.

## Basic Usage

Grape APIs are Rack applications that are created by subclassing `Grape::API`.
Below is a simple example showing some of the more common features of Grape in
the context of recreating parts of the Twitter API.

```ruby
module Twitter
  class API < Grape::API
    version 'v1', using: :header, vendor: 'twitter'
    format :json
    prefix :api

    helpers do
      def current_user
        @current_user ||= User.authorize!(env)
      end

      def authenticate!
        error!('401 Unauthorized', 401) unless current_user
      end
    end

    resource :statuses do
      desc 'Return a public timeline.'
      get :public_timeline do
        Status.limit(20)
      end

      desc 'Return a personal timeline.'
      get :home_timeline do
        authenticate!
        current_user.statuses.limit(20)
      end

      desc 'Return a status.'
      params do
        requires :id, type: Integer, desc: 'Status id.'
      end
      route_param :id do
        get do
          Status.find(params[:id])
        end
      end

      desc 'Create a status.'
      params do
        requires :status, type: String, desc: 'Your status.'
      end
      post do
        authenticate!
        Status.create!({
          user: current_user,
          text: params[:status]
        })
      end

      desc 'Update a status.'
      params do
        requires :id, type: String, desc: 'Status ID.'
        requires :status, type: String, desc: 'Your status.'
      end
      put ':id' do
        authenticate!
        current_user.statuses.find(params[:id]).update({
          user: current_user,
          text: params[:status]
        })
      end

      desc 'Delete a status.'
      params do
        requires :id, type: String, desc: 'Status ID.'
      end
      delete ':id' do
        authenticate!
        current_user.statuses.find(params[:id]).destroy
      end
    end
  end
end
```

## Mounting

### Rack

The above sample creates a Rack application that can be run from a rackup `config.ru` file
with `rackup`:

```ruby
run Twitter::API
```

And would respond to the following routes:

    GET /api/statuses/public_timeline
    GET /api/statuses/home_timeline
    GET /api/statuses/:id
    POST /api/statuses
    PUT /api/statuses/:id
    DELETE /api/statuses/:id

Grape will also automatically respond to HEAD and OPTIONS for all GET, and just OPTIONS for all other routes.

### ActiveRecord without Rails

If you want to use ActiveRecord within Grape, you will need to make sure that ActiveRecord's connection pool
is handled correctly.

The easiest way to achieve that is by using ActiveRecord's `ConnectionManagement` middleware in your
`config.ru` before mounting Grape, e.g.:

```ruby
use ActiveRecord::ConnectionAdapters::ConnectionManagement

run Twitter::API
```

### Alongside Sinatra (or other frameworks)

If you wish to mount Grape alongside another Rack framework such as Sinatra, you can do so easily using
`Rack::Cascade`:

```ruby
# Example config.ru

require 'sinatra'
require 'grape'

class API < Grape::API
  get :hello do
    { hello: 'world' }
  end
end

class Web < Sinatra::Base
  get '/' do
    'Hello world.'
  end
end

use Rack::Session::Cookie
run Rack::Cascade.new [API, Web]
```

### Rails

Place API files into `app/api`. Rails expects a subdirectory that matches the name of the Ruby module and a file name that matches the name of the class. In our example, the file name location and directory for `Twitter::API` should be `app/api/twitter/api.rb`.

Modify `application.rb`:

```ruby
config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
config.autoload_paths += Dir[Rails.root.join('app', 'api', '*')]
```

Modify `config/routes`:

```ruby
mount Twitter::API => '/'
```

Additionally, if the version of your Rails is 4.0+ and the application uses the default model layer of ActiveRecord, you will want to use the [hashie-forbidden_attributes gem](https://github.com/Maxim-Filimonov/hashie-forbidden_attributes). This gem disables the security feature of `strong_params` at the model layer, allowing you the use of Grape's own params validation instead.

```ruby
# Gemfile
gem 'hashie-forbidden_attributes'
```

See [below](#reloading-api-changes-in-development) for additional code that enables reloading of API changes in development.

### Modules

You can mount multiple API implementations inside another one. These don't have to be
different versions, but may be components of the same API.

```ruby
class Twitter::API < Grape::API
  mount Twitter::APIv1
  mount Twitter::APIv2
end
```

You can also mount on a path, which is similar to using `prefix` inside the mounted API itself.

```ruby
class Twitter::API < Grape::API
  mount Twitter::APIv1 => '/v1'
end
```

## Versioning

There are four strategies in which clients can reach your API's endpoints: `:path`,
`:header`, `:accept_version_header` and `:param`. The default strategy is `:path`.

### Path

```ruby
version 'v1', using: :path
```

Using this versioning strategy, clients should pass the desired version in the URL.

    curl http://localhost:9292/v1/statuses/public_timeline

### Header

```ruby
version 'v1', using: :header, vendor: 'twitter'
```

Currently, Grape only supports versioned media types in the following format:

```
vnd.vendor-and-or-resource-v1234+format
```

Basically all tokens between the final `-` and the `+` will be interpreted as the version.

Using this versioning strategy, clients should pass the desired version in the HTTP `Accept` head.

    curl -H Accept:application/vnd.twitter-v1+json http://localhost:9292/statuses/public_timeline

By default, the first matching version is used when no `Accept` header is
supplied. This behavior is similar to routing in Rails. To circumvent this default behavior,
one could use the `:strict` option. When this option is set to `true`, a `406 Not Acceptable` error
is returned when no correct `Accept` header is supplied.

When an invalid `Accept` header is supplied, a `406 Not Acceptable` error is returned if the `:cascade`
option is set to `false`. Otherwise a `404 Not Found` error is returned by Rack if no other route
matches.

### Accept-Version Header

```ruby
version 'v1', using: :accept_version_header
```

Using this versioning strategy, clients should pass the desired version in the HTTP `Accept-Version` header.

    curl -H "Accept-Version:v1" http://localhost:9292/statuses/public_timeline

By default, the first matching version is used when no `Accept-Version` header is
supplied. This behavior is similar to routing in Rails. To circumvent this default behavior,
one could use the `:strict` option. When this option is set to `true`, a `406 Not Acceptable` error
is returned when no correct `Accept` header is supplied.

### Param

```ruby
version 'v1', using: :param
```

Using this versioning strategy, clients should pass the desired version as a request parameter,
either in the URL query string or in the request body.

    curl http://localhost:9292/statuses/public_timeline?apiver=v1

The default name for the query parameter is 'apiver' but can be specified using the `:parameter` option.

```ruby
version 'v1', using: :param, parameter: 'v'
```

    curl http://localhost:9292/statuses/public_timeline?v=v1


## Describing Methods

You can add a description to API methods and namespaces.

```ruby
desc 'Returns your public timeline.' do
  detail 'more details'
  params  API::Entities::Status.documentation
  success API::Entities::Entity
  failure [[401, 'Unauthorized', 'Entities::Error']]
  named 'My named route'
  headers XAuthToken: {
            description: 'Valdates your identity',
            required: true
          },
          XOptionalHeader: {
            description: 'Not really needed',
            required: false
          }

end
get :public_timeline do
  Status.limit(20)
end
```

* `detail`: A more enhanced description
* `params`: Define parameters directly from an `Entity`
* `success`: (former entity) The `Entity` to be used to present by default this route
* `failure`: (former http_codes) A definition of the used failure HTTP Codes and Entities
* `named`: A helper to give a route a name and find it with this name in the documentation Hash
* `headers`: A definition of the used Headers

## Parameters

Request parameters are available through the `params` hash object. This includes `GET`, `POST`
and `PUT` parameters, along with any named parameters you specify in your route strings.

```ruby
get :public_timeline do
  Status.order(params[:sort_by])
end
```

Parameters are automatically populated from the request body on `POST` and `PUT` for form input, JSON and
XML content-types.

The request:

```
curl -d '{"text": "140 characters"}' 'http://localhost:9292/statuses' -H Content-Type:application/json -v
```

The Grape endpoint:

```ruby
post '/statuses' do
  Status.create!(text: params[:text])
end
```

Multipart POSTs and PUTs are supported as well.

The request:

```
curl --form image_file='@image.jpg;type=image/jpg' http://localhost:9292/upload
```

The Grape endpoint:

```ruby
post 'upload' do
  # file in params[:image_file]
end
```

In the case of conflict between either of:

* route string parameters
* `GET`, `POST` and `PUT` parameters
* the contents of the request body on `POST` and `PUT`

route string parameters will have precedence.

### Declared

Grape allows you to access only the parameters that have been declared by your `params` block. It filters out the params that have been passed, but are not allowed. Consider the following API endpoint:

````ruby
format :json

post 'users/signup' do
  { 'declared_params' => declared(params) }
end
````

If we do not specify any params, `declared` will return an empty `Hashie::Mash` instance.

**Request**

````bash
curl -X POST -H "Content-Type: application/json" localhost:9292/users/signup -d '{"user": {"first_name":"first name", "last_name": "last name"}}'
````

**Response**

````json
{
  "declared_params": {}
}

````

Once we add parameters requirements, grape will start returning only the declared params.

````ruby
format :json

params do
  requires :user, type: Hash do
    requires :first_name, type: String
    requires :last_name, type: String
  end
end

post 'users/signup' do
  { 'declared_params' => declared(params) }
end
````

**Request**

````bash
curl -X POST -H "Content-Type: application/json" localhost:9292/users/signup -d '{"user": {"first_name":"first name", "last_name": "last name", "random": "never shown"}}'
````

**Response**

````json
{
  "declared_params": {
    "user": {
      "first_name": "first name",
      "last_name": "last name"
    }
  }
}
````

The returned hash is a `Hashie::Mash` instance, allowing you to access parameters via dot notation:

```ruby
  declared(params).user == declared(params)['user']
```


The `#declared` method is not available to `before` filters, as those are evaluated prior
to parameter coercion.

### Include missing

By default `declared(params)` includes parameters that have `nil` values. If you want to return only the parameters that are not `nil`, you can use the `include_missing` option. By default, `include_missing` is set to `true`. Consider the following API:

````ruby
format :json

params do
  requires :first_name, type: String
  optional :last_name, type: String
end

post 'users/signup' do
  { 'declared_params' => declared(params, include_missing: false) }
end
````

**Request**

````bash
curl -X POST -H "Content-Type: application/json" localhost:9292/users/signup -d '{"user": {"first_name":"first name", "random": "never shown"}}'
````

**Response with include_missing:false**

````json
{
  "declared_params": {
    "user": {
      "first_name": "first name"
    }
  }
}
````

**Response with include_missing:true**

````json
{
  "declared_params": {
    "first_name": "first name",
    "last_name": null
  }
}
````

It also works on nested hashes:

````ruby
format :json

params do
  requires :user, :type => Hash do
    requires :first_name, type: String
    optional :last_name, type: String
    requires :address, :type => Hash do
      requires :city, type: String
      optional :region, type: String
    end
  end
end

post 'users/signup' do
  { 'declared_params' => declared(params, include_missing: false) }
end
````

**Request**

````bash
curl -X POST -H "Content-Type: application/json" localhost:9292/users/signup -d '{"user": {"first_name":"first name", "random": "never shown", "address": { "city": "SF"}}}'
````

**Response with include_missing:false**

````json
{
  "declared_params": {
    "user": {
      "first_name": "first name",
      "address": {
        "city": "SF"
      }
    }
  }
}
````

**Response with include_missing:true**

````json
{
  "declared_params": {
    "user": {
      "first_name": "first name",
      "last_name": null,
      "address": {
        "city": "Zurich",
        "region": null
      }
    }
  }
}
````

Note that an attribute with a `nil` value is not considered *missing* and will also be returned
when `include_missing` is set to `false`:

**Request**

````bash
curl -X POST -H "Content-Type: application/json" localhost:9292/users/signup -d '{"user": {"first_name":"first name", "last_name": null, "address": { "city": "SF"}}}'
````

**Response with include_missing:false**

````json
{
  "declared_params": {
    "user": {
      "first_name": "first name",
      "last_name": null,
      "address": { "city": "SF"}
    }
  }
}
````

## Parameter Validation and Coercion

You can define validations and coercion options for your parameters using a `params` block.

```ruby
params do
  requires :id, type: Integer
  optional :text, type: String, regexp: /\A[a-z]+\z/
  group :media do
    requires :url
  end
  optional :audio do
    requires :format, type: Symbol, values: [:mp3, :wav, :aac, :ogg], default: :mp3
  end
  mutually_exclusive :media, :audio
end
put ':id' do
  # params[:id] is an Integer
end
```

When a type is specified an implicit validation is done after the coercion to ensure
the output type is the one declared.

Optional parameters can have a default value.

```ruby
params do
  optional :color, type: String, default: 'blue'
  optional :random_number, type: Integer, default: -> { Random.rand(1..100) }
  optional :non_random_number, type: Integer, default:  Random.rand(1..100)
end
```

Note that default values will be passed through to any validation options specified.
The following example will always fail if `:color` is not explicitly provided.

```ruby
params do
  optional :color, type: String, default: 'blue', values: ['red', 'green']
end
```

The correct implementation is to ensure the default value passes all validations.

```ruby
params do
  optional :color, type: String, default: 'blue', values: ['blue', 'red', 'green']
end
```

### Supported Parameter Types

The following are all valid types, supported out of the box by Grape:

* Integer
* Float
* BigDecimal
* Numeric
* Date
* DateTime
* Time
* Boolean
* String
* Symbol
* Rack::Multipart::UploadedFile (alias `File`)
* JSON

### Custom Types and Coercions

Aside from the default set of supported types listed above, any class can be
used as a type so long as an explicit coercion method is supplied. If the type
implements a class-level `parse` method, Grape will use it automatically.
This method must take one string argument and return an instance of the correct
type, or raise an exception to indicate the value was invalid. E.g.,

```ruby
class Color
  attr_reader :value
  def initialize(color)
    @value = color
  end

  def self.parse(value)
    fail 'Invalid color' unless %w(blue red green).include?(value)
    new(value)
  end
end

# ...

params do
  requires :color, type: Color, default: Color.new('blue')
end

get '/stuff' do
  # params[:color] is already a Color.
  params[:color].value
end
```

Alternatively, a custom coercion method may be supplied for any type of parameter
using `coerce_with`. Any class or object may be given that implements a `parse` or
`call` method, in that order of precedence. The method must accept a single string
parameter, and the return value must match the given `type`.

```ruby
params do
  requires :passwd, type: String, coerce_with: Base64.method(:decode)
  requires :loud_color, type: Color, coerce_with: ->(c) { Color.parse(c.downcase) }

  requires :obj, type: Hash, coerce_with: JSON do
    requires :words, type: Array[String], coerce_with: ->(val) { val.split(/\s+/) }
    optional :time, type: Time, coerce_with: Chronic
  end
end
```

### Multipart File Parameters

Grape makes use of `Rack::Request`'s built-in support for multipart
file parameters. Such parameters can be declared with `type: File`:

```ruby
params do
  requires :avatar, type: File
end
post '/' do
  # Parameter will be wrapped using Hashie:
  params.avatar.filename # => 'avatar.png'
  params.avatar.type     # => 'image/png'
  params.avatar.tempfile # => #<File>
end
```

### First-Class `JSON` Types

Grape supports complex parameters given as JSON-formatted strings using the special `type: JSON`
declaration. JSON objects and arrays of objects are accepted equally, with nested validation
rules applied to all objects in either case:

```ruby
params do
  requires :json, type: JSON do
    requires :int, type: Integer, values: [1, 2, 3]
  end
end
get '/' do
  params[:json].inspect
end

# ...

client.get('/', json: '{"int":1}') # => "{:int=>1}"
client.get('/', json: '[{"int":"1"}]') # => "[{:int=>1}]"

client.get('/', json: '{"int":4}') # => HTTP 400
client.get('/', json: '[{"int":4}]') # => HTTP 400
```

Additionally `type: Array[JSON]` may be used, which explicitly marks the parameter as an array
of objects. If a single object is supplied it will be wrapped.

```ruby
params do
  requires :json, type: Array[JSON] do
    requires :int, type: Integer
  end
end
get '/' do
  params[:json].each { |obj| ... } # always works
end
```
For stricter control over the type of JSON structure which may be supplied,
use `type: Array, coerce_with: JSON` or `type: Hash, coerce_with: JSON`.

### Multiple Allowed Types

Variant-type parameters can be declared using the `types` option rather than `type`:

```ruby
params do
  requires :status_code, types: [Integer, String, Array[Integer, String]]
end
get '/' do
  params[:status_code].inspect
end

# ...

client.get('/', status_code: 'OK_GOOD') # => "OK_GOOD"
client.get('/', status_code: 300) # => 300
client.get('/', status_code: %w(404 NOT FOUND)) # => [404, "NOT", "FOUND"]
```

As a special case, variant-member-type collections may also be declared, by
passing a `Set` or `Array` with more than one member to `type`:

```ruby
params do
  requires :status_codes, type: Array[Integer,String]
end
get '/' do
  params[:status_codes].inspect
end

# ...

client.get('/', status_codes: %w(1 two)) # => [1, "two"]
```

### Validation of Nested Parameters

Parameters can be nested using `group` or by calling `requires` or `optional` with a block.
In the above example, this means `params[:media][:url]` is required along with `params[:id]`,
and `params[:audio][:format]` is required only if `params[:audio]` is present.
With a block, `group`, `requires` and `optional` accept an additional option `type` which can
be either `Array` or `Hash`, and defaults to `Array`. Depending on the value, the nested
parameters will be treated either as values of a hash or as values of hashes in an array.

```ruby
params do
  optional :preferences, type: Array do
    requires :key
    requires :value
  end

  requires :name, type: Hash do
    requires :first_name
    requires :last_name
  end
end
```

### Dependent Parameters

Suppose some of your parameters are only relevant if another parameter is given;
Grape allows you to express this relationship through the `given` method in your
parameters block, like so:

```ruby
params do
  optional :shelf_id, type: Integer
  given :shelf_id do
    requires :bin_id, type: Integer
  end
end
```

### Built-in Validators

#### `allow_blank`

Parameters can be defined as `allow_blank`, ensuring that they contain a value. By default, `requires`
only validates that a parameter was sent in the request, regardless its value. With `allow_blank: false`,
empty values or whitespace only values are invalid.

`allow_blank` can be combined with both `requires` and `optional`. If the parameter is required, it has to contain
a value. If it's optional, it's possible to not send it in the request, but if it's being sent, it has to have
some value, and not an empty string/only whitespaces.


```ruby
params do
  requires :username, allow_blank: false
  optional :first_name, allow_blank: false
end
```

#### `values`

Parameters can be restricted to a specific set of values with the `:values` option.

Default values are eagerly evaluated. Above `:non_random_number` will evaluate to the same
number for each call to the endpoint of this `params` block. To have the default evaluate
lazily with each request use a lambda, like `:random_number` above.

```ruby
params do
  requires :status, type: Symbol, values: [:not_started, :processing, :done]
  optional :numbers, type: Array[Integer], default: 1, values: [1, 2, 3, 5, 8]
end
```

Supplying a range to the `:values` option ensures that the parameter is (or parameters are) included in that range (using `Range#include?`).

```ruby
params do
  requires :latitude, type: Float, values: -90.0..+90.0
  requires :longitude, type: Float, values: -180.0..+180.0
  optional :letters, type: Array[String], values: 'a'..'z'
end
```

Note that *both* range endpoints have to be a `#kind_of?` your `:type` option (if you don't supplied the `:type` option, it will be guessed to be equal to the class of the range's first endpoint). So the following is invalid:

```ruby
params do
  requires :invalid1, type: Float, values: 0..10 # 0.kind_of?(Float) => false
  optional :invalid2, values: 0..10.0 # 10.0.kind_of?(0.class) => false
end
```

The `:values` option can also be supplied with a `Proc`, evaluated lazily with each request.
For example, given a status model you may want to restrict by hashtags that you have
previously defined in the `HashTag` model.

```ruby
params do
  requires :hashtag, type: String, values: -> { Hashtag.all.map(&:tag) }
end
```

#### `regexp`

Parameters can be restricted to match a specific regular expression with the `:regexp` option. If the value
does not match the regular expression an error will be returned. Note that this is true for both `requires`
and `optional` parameters.

```ruby
params do
  requires :email, regexp: /.+@.+/
end
```

The validator will pass if the parameter was sent without value. To ensure that the parameter contains a value, use `allow_blank: false`.

```ruby
params do
  requires :email, allow_blank: false, regexp: /.+@.+/
end
```

#### `mutually_exclusive`

Parameters can be defined as `mutually_exclusive`, ensuring that they aren't present at the same time in a request.

```ruby
params do
  optional :beer
  optional :wine
  mutually_exclusive :beer, :wine
end
```

Multiple sets can be defined:

```ruby
params do
  optional :beer
  optional :wine
  mutually_exclusive :beer, :wine
  optional :scotch
  optional :aquavit
  mutually_exclusive :scotch, :aquavit
end
```

**Warning**: Never define mutually exclusive sets with any required params. Two mutually exclusive required params will mean params are never valid, thus making the endpoint useless. One required param mutually exclusive with an optional param will mean the latter is never valid.

#### `exactly_one_of`

Parameters can be defined as 'exactly_one_of', ensuring that exactly one parameter gets selected.

```ruby
params do
  optional :beer
  optional :wine
  exactly_one_of :beer, :wine
end
```

#### `at_least_one_of`

Parameters can be defined as 'at_least_one_of', ensuring that at least one parameter gets selected.

```ruby
params do
  optional :beer
  optional :wine
  optional :juice
  at_least_one_of :beer, :wine, :juice
end
```

#### `all_or_none_of`

Parameters can be defined as 'all_or_none_of', ensuring that all or none of parameters gets selected.

```ruby
params do
  optional :beer
  optional :wine
  optional :juice
  all_or_none_of :beer, :wine, :juice
end
```

#### Nested `mutually_exclusive`, `exactly_one_of`, `at_least_one_of`, `all_or_none_of`

All of these methods can be used at any nested level.

```ruby
params do
  requires :food do
    optional :meat
    optional :fish
    optional :rice
    at_least_one_of :meat, :fish, :rice
  end
  group :drink do
    optional :beer
    optional :wine
    optional :juice
    exactly_one_of :beer, :wine, :juice
  end
  optional :dessert do
    optional :cake
    optional :icecream
    mutually_exclusive :cake, :icecream
  end
  optional :recipe do
    optional :oil
    optional :meat
    all_or_none_of :oil, :meat
  end
end
```

### Namespace Validation and Coercion

Namespaces allow parameter definitions and apply to every method within the namespace.

```ruby
namespace :statuses do
  params do
    requires :user_id, type: Integer, desc: 'A user ID.'
  end
  namespace ':user_id' do
    desc "Retrieve a user's status."
    params do
      requires :status_id, type: Integer, desc: 'A status ID.'
    end
    get ':status_id' do
      User.find(params[:user_id]).statuses.find(params[:status_id])
    end
  end
end
```

The `namespace` method has a number of aliases, including: `group`, `resource`,
`resources`, and `segment`. Use whichever reads the best for your API.

You can conveniently define a route parameter as a namespace using `route_param`.

```ruby
namespace :statuses do
  route_param :id do
    desc 'Returns all replies for a status.'
    get 'replies' do
      Status.find(params[:id]).replies
    end
    desc 'Returns a status.'
    get do
      Status.find(params[:id])
    end
  end
end
```

### Custom Validators

```ruby
class AlphaNumeric < Grape::Validations::Base
  def validate_param!(attr_name, params)
    unless params[attr_name] =~ /\A[[:alnum:]]+\z/
      fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: 'must consist of alpha-numeric characters'
    end
  end
end
```

```ruby
params do
  requires :text, alpha_numeric: true
end
```

You can also create custom classes that take parameters.

```ruby
class Length < Grape::Validations::Base
  def validate_param!(attr_name, params)
    unless params[attr_name].length <= @option
      fail Grape::Exceptions::Validation, params: [@scope.full_name(attr_name)], message: "must be at the most #{@option} characters long"
    end
  end
end
```

```ruby
params do
  requires :text, length: 140
end
```

### Validation Errors

Validation and coercion errors are collected and an exception of type `Grape::Exceptions::ValidationErrors` is raised. If the exception goes uncaught it will respond with a status of 400 and an error message. The validation errors are grouped by parameter name and can be accessed via `Grape::Exceptions::ValidationErrors#errors`.


The default response from a `Grape::Exceptions::ValidationErrors` is a humanly readable string, such as "beer, wine are mutually exclusive", in the following example.

```ruby
params do
  optional :beer
  optional :wine
  optional :juice
  exactly_one_of :beer, :wine, :juice
end
```

You can rescue a `Grape::Exceptions::ValidationErrors` and respond with a custom response or turn the response into well-formatted JSON for a JSON API that separates individual parameters and the corresponding error messages. The following `rescue_from` example produces `[{"params":["beer","wine"],"messages":["are mutually exclusive"]}]`.

```ruby
format :json
subject.rescue_from Grape::Exceptions::ValidationErrors do |e|
  error! e, 400
end
```

`Grape::Exceptions::ValidationErrors#full_messages` returns the validation messages as an array. `Grape::Exceptions::ValidationErrors#message` joins the messages to one string.

For responding with an array of validation messages, you can use `Grape::Exceptions::ValidationErrors#full_messages`.
```ruby
format :json
subject.rescue_from Grape::Exceptions::ValidationErrors do |e|
  error!({ messages: e.full_messages }, 400)
end
```

### I18n

Grape supports I18n for parameter-related error messages, but will fallback to English if
translations for the default locale have not been provided. See [en.yml](lib/grape/locale/en.yml) for message keys.

## Headers

Request headers are available through the `headers` helper or from `env` in their original form.

```ruby
get do
  error!('Unauthorized', 401) unless headers['Secret-Password'] == 'swordfish'
end
```

```ruby
get do
  error!('Unauthorized', 401) unless env['HTTP_SECRET_PASSWORD'] == 'swordfish'
end
```

You can set a response header with `header` inside an API.

```ruby
header 'X-Robots-Tag', 'noindex'
```

When raising `error!`, pass additional headers as arguments.

```ruby
error! 'Unauthorized', 401, 'X-Error-Detail' => 'Invalid token.'
```

## Routes

Optionally, you can define requirements for your named route parameters using regular
expressions on namespace or endpoint. The route will match only if all requirements are met.

```ruby
get ':id', requirements: { id: /[0-9]*/ } do
  Status.find(params[:id])
end

namespace :outer, requirements: { id: /[0-9]*/ } do
  get :id do
  end

  get ':id/edit' do
  end
end
```

## Helpers

You can define helper methods that your endpoints can use with the `helpers`
macro by either giving a block or a module.

```ruby
module StatusHelpers
  def user_info(user)
    "#{user} has statused #{user.statuses} status(s)"
  end
end

class API < Grape::API
  # define helpers with a block
  helpers do
    def current_user
      User.find(params[:user_id])
    end
  end

  # or mix in a module
  helpers StatusHelpers

  get 'info' do
    # helpers available in your endpoint and filters
    user_info(current_user)
  end
end
```

You can define reusable `params` using `helpers`.

```ruby
class API < Grape::API
  helpers do
    params :pagination do
      optional :page, type: Integer
      optional :per_page, type: Integer
    end
  end

  desc 'Get collection'
  params do
    use :pagination # aliases: includes, use_scope
  end
  get do
    Collection.page(params[:page]).per(params[:per_page])
  end
end
```

You can also define reusable `params` using shared helpers.

```ruby
module SharedParams
  extend Grape::API::Helpers

  params :period do
    optional :start_date
    optional :end_date
  end

  params :pagination do
    optional :page, type: Integer
    optional :per_page, type: Integer
  end
end

class API < Grape::API
  helpers SharedParams

  desc 'Get collection.'
  params do
    use :period, :pagination
  end

  get do
    Collection
      .from(params[:start_date])
      .to(params[:end_date])
      .page(params[:page])
      .per(params[:per_page])
  end
end
```

Helpers support blocks that can help set default values. The following API can return a collection sorted by `id` or `created_at` in `asc` or `desc` order.

```ruby
module SharedParams
  extend Grape::API::Helpers

  params :order do |options|
    optional :order_by, type:Symbol, values:options[:order_by], default:options[:default_order_by]
    optional :order, type:Symbol, values:%i(asc desc), default:options[:default_order]
  end
end

class API < Grape::API
  helpers SharedParams

  desc 'Get a sorted collection.'
  params do
    use :order, order_by:%i(id created_at), default_order_by: :created_at, default_order: :asc
  end

  get do
    Collection.send(params[:order], params[:order_by])
  end
end
```

## Path Helpers

If you need methods for generating paths inside your endpoints, please see the [grape-route-helpers](https://github.com/reprah/grape-route-helpers) gem.

## Parameter Documentation

You can attach additional documentation to `params` using a `documentation` hash.

```ruby
params do
  optional :first_name, type: String, documentation: { example: 'Jim' }
  requires :last_name, type: String, documentation: { example: 'Smith' }
end
```

## Cookies

You can set, get and delete your cookies very simply using `cookies` method.

```ruby
class API < Grape::API
  get 'status_count' do
    cookies[:status_count] ||= 0
    cookies[:status_count] += 1
    { status_count: cookies[:status_count] }
  end

  delete 'status_count' do
    { status_count: cookies.delete(:status_count) }
  end
end
```

Use a hash-based syntax to set more than one value.

```ruby
cookies[:status_count] = {
  value: 0,
  expires: Time.tomorrow,
  domain: '.twitter.com',
  path: '/'
}

cookies[:status_count][:value] +=1
```

Delete a cookie with `delete`.

```ruby
cookies.delete :status_count
```

Specify an optional path.

```ruby
cookies.delete :status_count, path: '/'
```

## HTTP Status Code

By default Grape returns a 200 status code for `GET`-Requests and 201 for `POST`-Requests.
You can use `status` to query and set the actual HTTP Status Code

```ruby
post do
  status 202

  if status == 200
     # do some thing
  end
end
```

You can also use one of status codes symbols that are provided by [Rack utils](http://www.rubydoc.info/github/rack/rack/Rack/Utils#HTTP_STATUS_CODES-constant)

```ruby
post do
  status :no_content
end
```

## Redirecting

You can redirect to a new url temporarily (302) or permanently (301).

```ruby
redirect '/statuses'
```

```ruby
redirect '/statuses', permanent: true
```

## Allowed Methods

When you add a `GET` route for a resource, a route for the `HEAD`
method will also be added automatically. You can disable this
behavior with `do_not_route_head!`.

``` ruby
class API < Grape::API
  do_not_route_head!

  get '/example' do
    # only responds to GET
  end
end
```

When you add a route for a resource, a route for the `OPTIONS`
method will also be added. The response to an OPTIONS request will
include an "Allow" header listing the supported methods.

```ruby
class API < Grape::API
  get '/rt_count' do
    { rt_count: current_user.rt_count }
  end

  params do
    requires :value, type: Integer, desc: 'Value to add to the rt count.'
  end
  put '/rt_count' do
    current_user.rt_count += params[:value].to_i
    { rt_count: current_user.rt_count }
  end
end
```

``` shell
curl -v -X OPTIONS http://localhost:3000/rt_count

> OPTIONS /rt_count HTTP/1.1
>
< HTTP/1.1 204 No Content
< Allow: OPTIONS, GET, PUT
```

You can disable this behavior with `do_not_route_options!`.

If a request for a resource is made with an unsupported HTTP method, an
HTTP 405 (Method Not Allowed) response will be returned.

``` shell
curl -X DELETE -v http://localhost:3000/rt_count/

> DELETE /rt_count/ HTTP/1.1
> Host: localhost:3000
>
< HTTP/1.1 405 Method Not Allowed
< Allow: OPTIONS, GET, PUT
```

## Raising Exceptions

You can abort the execution of an API method by raising errors with `error!`.

```ruby
error! 'Access Denied', 401
```

You can also return JSON formatted objects by raising error! and passing a hash
instead of a message.

```ruby
error!({ error: 'unexpected error', detail: 'missing widget' }, 500)
```

You can present documented errors with a Grape entity using the the [grape-entity](https://github.com/ruby-grape/grape-entity) gem.

```ruby
module API
  class Error < Grape::Entity
    expose :code
    expose :message
  end
end
```

The following example specifies the entity to use in the `http_codes` definition.

```
desc 'My Route' do
 failure [[408, 'Unauthorized', API::Error]]
end
error!({ message: 'Unauthorized' }, 408)
```

The following example specifies the presented entity explicitly in the error message.

```ruby
desc 'My Route' do
 failure [[408, 'Unauthorized']]
end
error!({ message: 'Unauthorized', with: API::Error }, 408)
```

### Default Error HTTP Status Code

By default Grape returns a 500 status code from `error!`. You can change this with `default_error_status`.

``` ruby
class API < Grape::API
  default_error_status 400
  get '/example' do
    error! 'This should have http status code 400'
  end
end
```

### Handling 404

For Grape to handle all the 404s for your API, it can be useful to use a catch-all.
In its simplest form, it can be like:

```ruby
route :any, '*path' do
  error! # or something else
end
```

It is very crucial to __define this endpoint at the very end of your API__, as it
literally accepts every request.

## Exception Handling

Grape can be told to rescue all exceptions and return them in the API format.

```ruby
class Twitter::API < Grape::API
  rescue_from :all
end
```

You can also rescue specific exceptions.

```ruby
class Twitter::API < Grape::API
  rescue_from ArgumentError, UserDefinedError
end
```

In this case ```UserDefinedError``` must be inherited from ```StandardError```.

The error format will match the request format. See "Content-Types" below.

Custom error formatters for existing and additional types can be defined with a proc.

```ruby
class Twitter::API < Grape::API
  error_formatter :txt, ->(message, backtrace, options, env) {
    "error: #{message} from #{backtrace}"
  }
end
```

You can also use a module or class.

```ruby
module CustomFormatter
  def self.call(message, backtrace, options, env)
    { message: message, backtrace: backtrace }
  end
end

class Twitter::API < Grape::API
  error_formatter :custom, CustomFormatter
end
```

You can rescue all exceptions with a code block. The `error!` wrapper automatically sets the default error code and content-type.

```ruby
class Twitter::API < Grape::API
  rescue_from :all do |e|
    error!("rescued from #{e.class.name}")
  end
end
```

Optionally, you can set the format, status code and headers.

```ruby
class Twitter::API < Grape::API
  format :json
  rescue_from :all do |e|
    error!({ error: 'Server error.' }, 500, { 'Content-Type' => 'text/error' })
  end
end
```

You can also rescue specific exceptions with a code block and handle the Rack response at the lowest level.

```ruby
class Twitter::API < Grape::API
  rescue_from :all do |e|
    Rack::Response.new([ e.message ], 500, { 'Content-type' => 'text/error' }).finish
  end
end
```

Or rescue specific exceptions.

```ruby
class Twitter::API < Grape::API
  rescue_from ArgumentError do |e|
    error!("ArgumentError: #{e.message}")
  end

  rescue_from NotImplementedError do |e|
    error!("NotImplementedError: #{e.message}")
  end
end
```

By default, `rescue_from` will rescue the exceptions listed and all their subclasses.

Assume you have the following exception classes defined.

```ruby
module APIErrors
  class ParentError < StandardError; end
  class ChildError < ParentError; end
end
```

Then the following `rescue_from` clause will rescue exceptions of type `APIErrors::ParentError` and its subclasses (in this case `APIErrors::ChildError`).

```ruby
rescue_from APIErrors::ParentError do |e|
    error!({
      error: "#{e.class} error",
      message: e.message
    }, e.status)
end
```

To only rescue the base exception class, set `rescue_subclasses: false`.
The code below will rescue exceptions of type `RuntimeError` but _not_ its subclasses.

```ruby
rescue_from RuntimeError, rescue_subclasses: false do |e|
    error!({
      status: e.status,
      message: e.message,
      errors: e.errors
    }, e.status)
end
```

The `rescue_from` block must return a `Rack::Response` object, call `error!` or re-raise an exception.

#### Unrescuable Exceptions

`Grape::Exceptions::InvalidVersionHeader`, which is raised when the version in the request header doesn't match the currently evaluated version for the endpoint, will _never_ be rescued from a `rescue_from` block (even a `rescue_from :all`) This is because Grape relies on Rack to catch that error and try the next versioned-route for cases where there exist identical Grape endpoints with different versions.

### Rails 3.x

When mounted inside containers, such as Rails 3.x, errors such as "404 Not Found" or
"406 Not Acceptable" will likely be handled and rendered by Rails handlers. For instance,
accessing a nonexistent route "/api/foo" raises a 404, which inside rails will ultimately
be translated to an `ActionController::RoutingError`, which most likely will get rendered
to a HTML error page.

Most APIs will enjoy preventing downstream handlers from handling errors. You may set the
`:cascade` option to `false` for the entire API or separately on specific `version` definitions,
which will remove the `X-Cascade: true` header from API responses.

```ruby
cascade false
```

```ruby
version 'v1', using: :header, vendor: 'twitter', cascade: false
```

## Logging

`Grape::API` provides a `logger` method which by default will return an instance of the `Logger`
class from Ruby's standard library.

To log messages from within an endpoint, you need to define a helper to make the logger
available in the endpoint context.

```ruby
class API < Grape::API
  helpers do
    def logger
      API.logger
    end
  end
  post '/statuses' do
    # ...
    logger.info "#{current_user} has statused"
  end
end
```

You can also set your own logger.

```ruby
class MyLogger
  def warning(message)
    puts "this is a warning: #{message}"
  end
end

class API < Grape::API
  logger MyLogger.new
  helpers do
    def logger
      API.logger
    end
  end
  get '/statuses' do
    logger.warning "#{current_user} has statused"
  end
end
```

For similar to Rails request logging try the [grape_logging](https://github.com/aserafin/grape_logging) gem.

## API Formats

Your API can declare which content-types to support by using `content_type`. If you do not specify any, Grape will support
_XML_, _JSON_, _BINARY_, and _TXT_ content-types. The default format is `:txt`; you can change this with `default_format`.
Essentially, the two APIs below are equivalent.

```ruby
class Twitter::API < Grape::API
  # no content_type declarations, so Grape uses the defaults
end

class Twitter::API < Grape::API
  # the following declarations are equivalent to the defaults

  content_type :xml, 'application/xml'
  content_type :json, 'application/json'
  content_type :binary, 'application/octet-stream'
  content_type :txt, 'text/plain'

  default_format :txt
end
```

If you declare any `content_type` whatsoever, the Grape defaults will be overridden. For example, the following API will only
support the `:xml` and `:rss` content-types, but not `:txt`, `:json`, or `:binary`. Importantly, this means the `:txt`
default format is not supported! So, make sure to set a new `default_format`.

```ruby
class Twitter::API < Grape::API
  content_type :xml, 'application/xml'
  content_type :rss, 'application/xml+rss'

  default_format :xml
end
```

Serialization takes place automatically. For example, you do not have to call `to_json` in each JSON API endpoint
implementation. The response format (and thus the automatic serialization) is determined in the following order:
* Use the file extension, if specified. If the file is .json, choose the JSON format.
* Use the value of the `format` parameter in the query string, if specified.
* Use the format set by the `format` option, if specified.
* Attempt to find an acceptable format from the `Accept` header.
* Use the default format, if specified by the `default_format` option.
* Default to `:txt`.

For example, consider the following API.

```ruby
class MultipleFormatAPI < Grape::API
  content_type :xml, 'application/xml'
  content_type :json, 'application/json'

  default_format :json

  get :hello do
    { hello: 'world' }
  end
end
```

* `GET /hello` (with an `Accept: */*` header) does not have an extension or a `format` parameter, so it will respond with
  JSON (the default format).
* `GET /hello.xml` has a recognized extension, so it will respond with XML.
* `GET /hello?format=xml` has a recognized `format` parameter, so it will respond with XML.
* `GET /hello.xml?format=json` has a recognized extension (which takes precedence over the `format` parameter), so it will
  respond with XML.
* `GET /hello.xls` (with an `Accept: */*` header) has an extension, but that extension is not recognized, so it will respond
  with JSON (the default format).
* `GET /hello.xls` with an `Accept: application/xml` header has an unrecognized extension, but the `Accept` header
  corresponds to a recognized format, so it will respond with XML.
* `GET /hello.xls` with an `Accept: text/plain` header has an unrecognized extension *and* an unrecognized `Accept` header,
  so it will respond with JSON (the default format).

You can override this process explicitly by specifying `env['api.format']` in the API itself.
For example, the following API will let you upload arbitrary files and return their contents as an attachment with the correct MIME type.

```ruby
class Twitter::API < Grape::API
  post 'attachment' do
    filename = params[:file][:filename]
    content_type MIME::Types.type_for(filename)[0].to_s
    env['api.format'] = :binary # there's no formatter for :binary, data will be returned "as is"
    header 'Content-Disposition', "attachment; filename*=UTF-8''#{URI.escape(filename)}"
    params[:file][:tempfile].read
  end
end
```

You can have your API only respond to a single format with `format`. If you use this, the API will **not** respond to file
extensions other than specified in `format`. For example, consider the following API.

```ruby
class SingleFormatAPI < Grape::API
  format :json

  get :hello do
    { hello: 'world' }
  end
end
```

* `GET /hello` will respond with JSON.
* `GET /hello.json` will respond with JSON.
* `GET /hello.xml`, `GET /hello.foobar`, or *any* other extension will respond with an HTTP 404 error code.
* `GET /hello?format=xml` will respond with an HTTP 406 error code, because the XML format specified by the request parameter
  is not supported.
* `GET /hello` with an `Accept: application/xml` header will still respond with JSON, since it could not negotiate a
  recognized content-type from the headers and JSON is the effective default.

The formats apply to parsing, too. The following API will only respond to the JSON content-type and will not parse any other
input than `application/json`, `application/x-www-form-urlencoded`, `multipart/form-data`, `multipart/related` and
`multipart/mixed`. All other requests will fail with an HTTP 406 error code.

```ruby
class Twitter::API < Grape::API
  format :json
end
```

When the content-type is omitted, Grape will return a 406 error code unless `default_format` is specified.
The following API will try to parse any data without a content-type using a JSON parser.

```ruby
class Twitter::API < Grape::API
  format :json
  default_format :json
end
```

If you combine `format` with `rescue_from :all`, errors will be rendered using the same format.
If you do not want this behavior, set the default error formatter with `default_error_formatter`.

```ruby
class Twitter::API < Grape::API
  format :json
  content_type :txt, 'text/plain'
  default_error_formatter :txt
end
```

Custom formatters for existing and additional types can be defined with a proc.

```ruby
class Twitter::API < Grape::API
  content_type :xls, 'application/vnd.ms-excel'
  formatter :xls, ->(object, env) { object.to_xls }
end
```

You can also use a module or class.

```ruby
module XlsFormatter
  def self.call(object, env)
    object.to_xls
  end
end

class Twitter::API < Grape::API
  content_type :xls, 'application/vnd.ms-excel'
  formatter :xls, XlsFormatter
end
```

Built-in formatters are the following.

* `:json`: use object's `to_json` when available, otherwise call `MultiJson.dump`
* `:xml`: use object's `to_xml` when available, usually via `MultiXml`, otherwise call `to_s`
* `:txt`: use object's `to_txt` when available, otherwise `to_s`
* `:serializable_hash`: use object's `serializable_hash` when available, otherwise fallback to `:json`
* `:binary`: data will be returned "as is"

Response statuses that indicate no content as defined by [Rack](https://github.com/rack)
[here](https://github.com/rack/rack/blob/master/lib/rack/utils.rb#L567)
will bypass serialization and the body entity - though there should be none -
will not be modified.

### JSONP

Grape supports JSONP via [Rack::JSONP](https://github.com/rack/rack-contrib), part of the
[rack-contrib](https://github.com/rack/rack-contrib) gem. Add `rack-contrib` to your `Gemfile`.

```ruby
require 'rack/contrib'

class API < Grape::API
  use Rack::JSONP
  format :json
  get '/' do
    'Hello World'
  end
end
```

### CORS

Grape supports CORS via [Rack::CORS](https://github.com/cyu/rack-cors), part of the
[rack-cors](https://github.com/cyu/rack-cors) gem. Add `rack-cors` to your `Gemfile`,
then use the middleware in your config.ru file.

```ruby
require 'rack/cors'

use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: :get
  end
end

run Twitter::API

```

## Content-type

Content-type is set by the formatter. You can override the content-type of the response at runtime
by setting the `Content-Type` header.

```ruby
class API < Grape::API
  get '/home_timeline_js' do
    content_type 'application/javascript'
    "var statuses = ...;"
  end
end
```

## API Data Formats

Grape accepts and parses input data sent with the POST and PUT methods as described in the Parameters
section above. It also supports custom data formats. You must declare additional content-types via
`content_type` and optionally supply a parser via `parser` unless a parser is already available within
Grape to enable a custom format. Such a parser can be a function or a class.

With a parser, parsed data is available "as-is" in `env['api.request.body']`.
Without a parser, data is available "as-is" and in `env['api.request.input']`.

The following example is a trivial parser that will assign any input with the "text/custom" content-type
to `:value`. The parameter will be available via `params[:value]` inside the API call.

```ruby
module CustomParser
  def self.call(object, env)
    { value: object.to_s }
  end
end
```

```ruby
content_type :txt, 'text/plain'
content_type :custom, 'text/custom'
parser :custom, CustomParser

put 'value' do
  params[:value]
end
```

You can invoke the above API as follows.

```
curl -X PUT -d 'data' 'http://localhost:9292/value' -H Content-Type:text/custom -v
```

You can disable parsing for a content-type with `nil`. For example, `parser :json, nil` will disable JSON parsing altogether. The request data is then available as-is in `env['api.request.body']`.

## RESTful Model Representations

Grape supports a range of ways to present your data with some help from a generic `present` method,
which accepts two arguments: the object to be presented and the options associated with it. The options
hash may include `:with`, which defines the entity to expose.

### Grape Entities

Add the [grape-entity](https://github.com/ruby-grape/grape-entity) gem to your Gemfile.
Please refer to the [grape-entity documentation](https://github.com/ruby-grape/grape-entity/blob/master/README.md)
for more details.

The following example exposes statuses.

```ruby
module API
  module Entities
    class Status < Grape::Entity
      expose :user_name
      expose :text, documentation: { type: 'string', desc: 'Status update text.' }
      expose :ip, if: { type: :full }
      expose :user_type, :user_id, if: ->(status, options) { status.user.public? }
      expose :digest { |status, options| Digest::MD5.hexdigest(status.txt) }
      expose :replies, using: API::Status, as: :replies
    end
  end

  class Statuses < Grape::API
    version 'v1'

    desc 'Statuses index' do
      params: API::Entities::Status.documentation
    end
    get '/statuses' do
      statuses = Status.all
      type = current_user.admin? ? :full : :default
      present statuses, with: API::Entities::Status, type: type
    end
  end
end
```

You can use entity documentation directly in the params block with `using: Entity.documentation`.

```ruby
module API
  class Statuses < Grape::API
    version 'v1'

    desc 'Create a status'
    params do
      requires :all, except: [:ip], using: API::Entities::Status.documentation.except(:id)
    end
    post '/status' do
      Status.create! params
    end
  end
end
```

You can present with multiple entities using an optional Symbol argument.

```ruby
  get '/statuses' do
    statuses = Status.all.page(1).per(20)
    present :total_page, 10
    present :per_page, 20
    present :statuses, statuses, with: API::Entities::Status
  end
```

The response will be

```
  {
    total_page: 10,
    per_page: 20,
    statuses: []
  }
```

In addition to separately organizing entities, it may be useful to put them as namespaced
classes underneath the model they represent.

```ruby
class Status
  def entity
    Entity.new(self)
  end

  class Entity < Grape::Entity
    expose :text, :user_id
  end
end
```

If you organize your entities this way, Grape will automatically detect the `Entity` class and
use it to present your models. In this example, if you added `present Status.new` to your endpoint,
Grape will automatically detect that there is a `Status::Entity` class and use that as the
representative entity. This can still be overridden by using the `:with` option or an explicit
`represents` call.

You can present `hash` with `Grape::Presenters::Presenter` to keep things consistent.

```ruby
get '/users' do
  present { id: 10, name: :dgz }, with: Grape::Presenters::Presenter
end
````
The response will be

```ruby
{
  id:   10,
  name: 'dgz'
}
```

It has the same result with

```ruby
get '/users' do
  present :id, 10
  present :name, :dgz
end
```

### Hypermedia and Roar

You can use [Roar](https://github.com/apotonick/roar) to render HAL or Collection+JSON with the help of [grape-roar](https://github.com/ruby-grape/grape-roar), which defines a custom JSON formatter and enables presenting entities with Grape's `present` keyword.

### Rabl

You can use [Rabl](https://github.com/nesquena/rabl) templates with the help of the
[grape-rabl](https://github.com/ruby-grape/grape-rabl) gem, which defines a custom Grape Rabl
formatter.

### Active Model Serializers

You can use [Active Model Serializers](https://github.com/rails-api/active_model_serializers) serializers with the help of the
[grape-active_model_serializers](https://github.com/jrhe/grape-active_model_serializers) gem, which defines a custom Grape AMS
formatter.

## Sending Raw or No Data

In general, use the binary format to send raw data.

```ruby
class API < Grape::API
  get '/file' do
    content_type 'application/octet-stream'
    File.binread 'file.bin'
  end
end
```

You can set the response body explicitly with `body`.

```ruby
class API < Grape::API
  get '/' do
    content_type 'text/plain'
    body 'Hello World'
    # return value ignored
  end
end
```

Use `body false` to return `204 No Content` without any data or content-type.

You can also set the response to a file-like object with `file`.
Note: Rack will read your entire Enumerable before returning a response. If
you would like to stream the response, see `stream`.

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

class API < Grape::API
  get '/' do
    file FileStreamer.new('file.bin')
  end
end
```

If you want a file-like object to be streamed using Rack::Chunked, use `stream`.

```ruby
class API < Grape::API
  get '/' do
    stream FileStreamer.new('file.bin')
  end
end
```

## Authentication

### Basic and Digest Auth

Grape has built-in Basic and Digest authentication (the given `block`
is executed in the context of the current `Endpoint`).  Authentication
applies to the current namespace and any children, but not parents.

```ruby
http_basic do |username, password|
  # verify user's password here
  { 'test' => 'password1' }[username] == password
end
```

```ruby
http_digest({ realm: 'Test Api', opaque: 'app secret' }) do |username|
  # lookup the user's password here
  { 'user1' => 'password1' }[username]
end
```

### Register custom middleware for authentication

Grape can use custom Middleware for authentication. How to implement these
Middleware have a look at `Rack::Auth::Basic` or similar implementations.


For registering a Middleware you need the following options:

* `label` - the name for your authenticator to use it later
* `MiddlewareClass` - the MiddlewareClass to use for authentication
* `option_lookup_proc` - A Proc with one Argument to lookup the options at
runtime (return value is an `Array` as Parameter for the Middleware).

Example:

```ruby

Grape::Middleware::Auth::Strategies.add(:my_auth, AuthMiddleware, ->(options) { [options[:realm]] } )


auth :my_auth, { realm: 'Test Api'} do |credentials|
  # lookup the user's password here
  { 'user1' => 'password1' }[username]
end

```

Use [warden-oauth2](https://github.com/opperator/warden-oauth2) or [rack-oauth2](https://github.com/nov/rack-oauth2) for OAuth2 support.

## Describing and Inspecting an API

Grape routes can be reflected at runtime. This can notably be useful for generating documentation.

Grape exposes arrays of API versions and compiled routes. Each route contains a `route_prefix`, `route_version`, `route_namespace`, `route_method`, `route_path` and `route_params`. You can add custom route settings to the route metadata with `route_setting`.

```ruby
class TwitterAPI < Grape::API
  version 'v1'
  desc 'Includes custom settings.'
  route_setting :custom, key: 'value'
  get do

  end
end
```

Examine the routes at runtime.

```ruby
TwitterAPI::versions # yields [ 'v1', 'v2' ]
TwitterAPI::routes # yields an array of Grape::Route objects
TwitterAPI::routes[0].route_version # => 'v1'
TwitterAPI::routes[0].route_description # => 'Includes custom settings.'
TwitterAPI::routes[0].route_settings[:custom] # => { key: 'value' }
```

## Current Route and Endpoint

It's possible to retrieve the information about the current route from within an API call with `route`.

```ruby
class MyAPI < Grape::API
  desc 'Returns a description of a parameter.'
  params do
    requires :id, type: Integer, desc: 'Identity.'
  end
  get 'params/:id' do
    route.route_params[params[:id]] # yields the parameter description
  end
end
```

The current endpoint responding to the request is `self` within the API block
or `env['api.endpoint']` elsewhere. The endpoint has some interesting properties,
such as `source` which gives you access to the original code block of the API
implementation. This can be particularly useful for building a logger middleware.

```ruby
class ApiLogger < Grape::Middleware::Base
  def before
    file = env['api.endpoint'].source.source_location[0]
    line = env['api.endpoint'].source.source_location[1]
    logger.debug "[api] #{file}:#{line}"
  end
end
```

## Before and After

Blocks can be executed before or after every API call, using `before`, `after`,
`before_validation` and `after_validation`.

Before and after callbacks execute in the following order:

1. `before`
2. `before_validation`
3. _validations_
4. `after_validation`
5. _the API call_
6. `after`

Steps 4, 5 and 6 only happen if validation succeeds.

E.g. using `before`:

```ruby
before do
  header 'X-Robots-Tag', 'noindex'
end
```

The block applies to every API call within and below the current namespace:

```ruby
class MyAPI < Grape::API
  get '/' do
    "root - #{@blah}"
  end

  namespace :foo do
    before do
      @blah = 'blah'
    end

    get '/' do
      "root - foo - #{@blah}"
    end

    namespace :bar do
      get '/' do
        "root - foo - bar - #{@blah}"
      end
    end
  end
end
```

The behaviour is then:

```bash
GET /           # 'root - '
GET /foo        # 'root - foo - blah'
GET /foo/bar    # 'root - foo - bar - blah'
```

Params on a `namespace` (or whatever alias you are using) also work when using
`before_validation` or `after_validation`:

```ruby
class MyAPI < Grape::API
  params do
    requires :blah, type: Integer
  end
  resource ':blah' do
    after_validation do
      # if we reach this point validations will have passed
      @blah = declared(params, include_missing: false)[:blah]
    end

    get '/' do
      @blah.class
    end
  end
end
```

The behaviour is then:

```bash
GET /123        # 'Fixnum'
GET /foo        # 400 error - 'blah is invalid'
```

When a callback is defined within a version block, it's only called for the routes defined in that block.

```ruby
class Test < Grape::API
  resource :foo do
    version 'v1', :using => :path do
      before do
        @output ||= 'v1-'
      end
      get '/' do
        @output += 'hello'
      end
    end

    version 'v2', :using => :path do
      before do
        @output ||= 'v2-'
      end
      get '/' do
        @output += 'hello'
      end
    end
  end
end
```

The behaviour is then:

```bash
GET /foo/v1       # 'v1-hello'
GET /foo/v2       # 'v2-hello'
```

## Anchoring

Grape by default anchors all request paths, which means that the request URL
should match from start to end to match, otherwise a `404 Not Found` is
returned. However, this is sometimes not what you want, because it is not always
known upfront what can be expected from the call. This is because Rack-mount by
default anchors requests to match from the start to the end, or not at all.
Rails solves this problem by using a `anchor: false` option in your routes.
In Grape this option can be used as well when a method is defined.

For instance when your API needs to get part of an URL, for instance:

```ruby
class TwitterAPI < Grape::API
  namespace :statuses do
    get '/(*:status)', anchor: false do

    end
  end
end
```

This will match all paths starting with '/statuses/'. There is one caveat though:
the `params[:status]` parameter only holds the first part of the request url.
Luckily this can be circumvented by using the described above syntax for path
specification and using the `PATH_INFO` Rack environment variable, using
`env['PATH_INFO']`. This will hold everything that comes after the '/statuses/'
part.

## Using Custom Middleware

### Rails Middleware

Note that when you're using Grape mounted on Rails you don't have to use Rails middleware because it's already included into your middleware stack.
You only have to implement the helpers to access the specific `env` variable.

### Remote IP

By default you can access remote IP with `request.ip`. This is the remote IP address implemented by Rack. Sometimes it is desirable to get the remote IP [Rails-style](http://stackoverflow.com/questions/10997005/whats-the-difference-between-request-remote-ip-and-request-ip-in-rails) with `ActionDispatch::RemoteIp`.

Add `gem 'actionpack'` to your Gemfile and `require 'action_dispatch/middleware/remote_ip.rb'`. Use the middleware in your API and expose a `client_ip` helper. See [this documentation](http://api.rubyonrails.org/classes/ActionDispatch/RemoteIp.html) for additional options.

```ruby
class API < Grape::API
  use ActionDispatch::RemoteIp

  helpers do
    def client_ip
      env['action_dispatch.remote_ip'].to_s
    end
  end

  get :remote_ip do
    { ip: client_ip }
  end
end
```

## Writing Tests

### Writing Tests with Rack

Use `rack-test` and define your API as `app`.

#### RSpec

You can test a Grape API with RSpec by making HTTP requests and examining the response.

```ruby
require 'spec_helper'

describe Twitter::API do
  include Rack::Test::Methods

  def app
    Twitter::API
  end

  context 'GET /api/statuses/public_timeline' do
    it 'returns an empty array of statuses' do
      get '/api/statuses/public_timeline'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq []
    end
  end
  context 'GET /api/statuses/:id' do
    it 'returns a status by id' do
      status = Status.create!
      get "/api/statuses/#{status.id}"
      expect(last_response.body).to eq status.to_json
    end
  end
end
```

There's no standard way of sending arrays of objects via an HTTP GET, so POST JSON data and specify the correct content-type.

```ruby
describe Twitter::API do
  context 'POST /api/statuses' do
    it 'creates many statuses' do
      statuses = [{ text: '...' }, { text: '...'}]
      post '/api/statuses', statuses.to_json, 'CONTENT_TYPE' => 'application/json'
      expect(last_response.body).to eq 201
    end
  end
end
```

#### Airborne

You can test with other RSpec-based frameworks, including [Airborne](https://github.com/brooklynDev/airborne), which uses `rack-test` to make requests.

```ruby
require 'airborne'

Airborne.configure do |config|
  config.rack_app = Twitter::API
end

describe Twitter::API do
  context 'GET /api/statuses/:id' do
    it 'returns a status by id' do
      status = Status.create!
      get "/api/statuses/#{status.id}"
      expect_json(status.as_json)
    end
  end
end
```

#### MiniTest

```ruby
require 'test_helper'

class Twitter::APITest < MiniTest::Test
  include Rack::Test::Methods

  def app
    Twitter::API
  end

  def test_get_api_statuses_public_timeline_returns_an_empty_array_of_statuses
    get '/api/statuses/public_timeline'
    assert last_response.ok?
    assert_equal [], JSON.parse(last_response.body)
  end

  def test_get_api_statuses_id_returns_a_status_by_id
    status = Status.create!
    get "/api/statuses/#{status.id}"
    assert_equal status.to_json, last_response.body
  end
end
```

### Writing Tests with Rails

#### RSpec

```ruby
describe Twitter::API do
  context 'GET /api/statuses/public_timeline' do
    it 'returns an empty array of statuses' do
      get '/api/statuses/public_timeline'
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)).to eq []
    end
  end
  context 'GET /api/statuses/:id' do
    it 'returns a status by id' do
      status = Status.create!
      get "/api/statuses/#{status.id}"
      expect(response.body).to eq status.to_json
    end
  end
end
```

In Rails, HTTP request tests would go into the `spec/requests` group. You may want your API code to go into
`app/api` - you can match that layout under `spec` by adding the following in `spec/spec_helper.rb`.

```ruby
RSpec.configure do |config|
  config.include RSpec::Rails::RequestExampleGroup, type: :request, file_path: /spec\/api/
end
```

#### MiniTest

```ruby
class Twitter::APITest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def app
    Rails.application
  end

  test 'GET /api/statuses/public_timeline returns an empty array of statuses' do
    get '/api/statuses/public_timeline'
    assert last_response.ok?
    assert_equal [], JSON.parse(last_response.body)
  end

  test 'GET /api/statuses/:id returns a status by id' do
    status = Status.create!
    get "/api/statuses/#{status.id}"
    assert_equal status.to_json, last_response.body
  end
end
```

### Stubbing Helpers

Because helpers are mixed in based on the context when an endpoint is defined, it can
be difficult to stub or mock them for testing. The `Grape::Endpoint.before_each` method
can help by allowing you to define behavior on the endpoint that will run before every
request.

```ruby
describe 'an endpoint that needs helpers stubbed' do
  before do
    Grape::Endpoint.before_each do |endpoint|
      allow(endpoint).to receive(:helper_name).and_return('desired_value')
    end
  end

  after do
    Grape::Endpoint.before_each nil
  end

  it 'should properly stub the helper' do
    # ...
  end
end
```

## Reloading API Changes in Development

### Reloading in Rack Applications

Use [grape-reload](https://github.com/AlexYankee/grape-reload).

### Reloading in Rails Applications

Add API paths to `config/application.rb`.

```ruby
# Auto-load API and its subdirectories
config.paths.add File.join('app', 'api'), glob: File.join('**', '*.rb')
config.autoload_paths += Dir[Rails.root.join('app', 'api', '*')]
```

Create `config/initializers/reload_api.rb`.

```ruby
if Rails.env.development?
  ActiveSupport::Dependencies.explicitly_unloadable_constants << 'Twitter::API'

  api_files = Dir[Rails.root.join('app', 'api', '**', '*.rb')]
  api_reloader = ActiveSupport::FileUpdateChecker.new(api_files) do
    Rails.application.reload_routes!
  end
  ActionDispatch::Callbacks.to_prepare do
    api_reloader.execute_if_updated
  end
end
```

See [StackOverflow #3282655](http://stackoverflow.com/questions/3282655/ruby-on-rails-3-reload-lib-directory-for-each-request/4368838#4368838) for more information.

## Performance Monitoring

### Active Support Instrumentation

Grape has built-in support for [ActiveSupport::Notifications](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html) which provides simple hook points to instrument key parts of your application.

The following are currently supported:

#### endpoint_run.grape

The main execution of an endpoint, includes filters and rendering.

* *endpoint* - The endpoint instance

#### endpoint_render.grape

The execution of the main content block of the endpoint.

* *endpoint* - The endpoint instance

#### endpoint_run_filters.grape

* *endpoint* - The endpoint instance
* *filters* - The filters being executed
* *type* - The type of filters (before, before_validation, after_validation, after)

See the [ActiveSupport::Notifications documentation](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html) for information on how to subscribe to these events.

### Monitoring Products

Grape integrates with following third-party tools:

* **New Relic** - [built-in support](https://docs.newrelic.com/docs/agents/ruby-agent/frameworks/grape-instrumentation) from v3.10.0 of the official [newrelic_rpm](https://github.com/newrelic/rpm) gem, also [newrelic-grape](https://github.com/xinminlabs/newrelic-grape) gem
* **Librato Metrics** - [grape-librato](https://github.com/seanmoon/grape-librato) gem
* **[Skylight](https://www.skylight.io/)** - [skylight](https://github.com/skylightio/skylight-ruby) gem, [documentation](https://docs.skylight.io/grape/)

## Contributing to Grape

Grape is work of hundreds of contributors. You're encouraged to submit pull requests, propose
features and discuss issues.

See [CONTRIBUTING](CONTRIBUTING.md).

## License

MIT License. See LICENSE for details.

## Copyright

Copyright (c) 2010-2015 Michael Bleigh, and Intridea, Inc.
