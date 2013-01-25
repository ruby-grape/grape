![grape logo](https://github.com/intridea/grape/wiki/grape_logo.png)

## What is Grape?

Grape is a REST-like API micro-framework for Ruby. It's designed to run on Rack
or complement existing web application frameworks such as Rails and Sinatra by
providing a simple DSL to easily develop RESTful APIs. It has built-in support
for common conventions, including multiple formats, subdomain/prefix restriction,
content negotiation, versioning and much more.

[![Build Status](https://travis-ci.org/intridea/grape.png?branch=master)](http://travis-ci.org/intridea/grape)

## Stable Release

You're reading the documentation for the next release of Grape, which should be 0.3.
The current stable release is [0.2.6](https://github.com/intridea/grape/blob/v0.2.6/README.markdown).

## Project Tracking

* [Grape Google Group](http://groups.google.com/group/ruby-grape)
* [Grape Wiki](https://github.com/intridea/grape/wiki)

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

    version 'v1', :using => :header, :vendor => 'twitter'
    format :json

    helpers do
      def current_user
        @current_user ||= User.authorize!(env)
      end

      def authenticate!
        error!('401 Unauthorized', 401) unless current_user
      end
    end

    resource :statuses do

      desc "Return a public timeline."
      get :public_timeline do
        Status.limit(20)
      end

      desc "Return a personal timeline."
      get :home_timeline do
        authenticate!
        current_user.statuses.limit(20)
      end

      desc "Return a status."
      params do
        requires :id, :type => Integer, :desc => "Status id."
      end
      get ':id' do
        Status.find(params[:id])
      end

      desc "Create a status."
      params do
        requires :status, :type => String, :desc => "Your status."
      end
      post do
        authenticate!
        Status.create!({
          :user => current_user,
          :text => params[:status]
        })
      end

      desc "Update a status."
      params do
        requires :id, :type => String, :desc => "Status ID."
        requires :status, :type => String, :desc => "Your status."
      end
      put ':id' do
        authenticate!
        current_user.statuses.find(params[:id]).update({
          :user => current_user,
          :text => params[:status]
        })
      end

      desc "Delete a status."
      params do
        requires :id, :type => String, :desc => "Status ID."
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

The above sample creates a Rack application that can be run from a rackup *config.ru* file
with `rackup`:

```ruby
run Twitter::API
```

And would respond to the following routes:

    GET /statuses/public_timeline(.json)
    GET /statuses/home_timeline(.json)
    GET /statuses/:id(.json)
    POST /statuses(.json)
    PUT /statuses/:id(.json)
    DELETE /statuses/:id(.json)

### Rails

In a Rails application, modify *config/routes*:

```ruby
mount Twitter::API
```

Note that when using Rails you will need to restart the server to pick up changes in your API classes
(see [Issue 131](https://github.com/intridea/grape/issues/131)).

### Modules

You can mount multiple API implementations inside another one. These don't have to be
different versions, but may be components of the same API.

```ruby
class Twitter::API < Grape::API
  mount Twitter::APIv1
  mount Twitter::APIv2
end
```

## Versioning

There are three strategies in which clients can reach your API's endpoints: `:header`,
`:path` and `:param`. The default strategy is `:path`.

### Header

```ruby
version 'v1', :using => :header, :vendor => 'twitter'
```

Using this versioning strategy, clients should pass the desired version in the HTTP `Accept` head.

    curl -H Accept=application/vnd.twitter-v1+json http://localhost:9292/statuses/public_timeline

By default, the first matching version is used when no `Accept` header is
supplied. This behavior is similar to routing in Rails. To circumvent this default behavior,
one could use the `:strict` option. When this option is set to `true`, a `406 Not Acceptable` error
is returned when no correct `Accept` header is supplied.

### Path

```ruby
version 'v1', :using => :path
```

Using this versioning strategy, clients should pass the desired version in the URL.

    curl -H http://localhost:9292/v1/statuses/public_timeline

### Param

```ruby
version 'v1', :using => :param
```

Using this versioning strategy, clients should pass the desired version as a request parameter,
either in the URL query string or in the request body.

    curl -H http://localhost:9292/statuses/public_timeline?apiver=v1

The default name for the query parameter is 'apiver' but can be specified using the `:parameter` option.

```ruby
version 'v1', :using => :param, :parameter => "v"
```

    curl -H http://localhost:9292/statuses/public_timeline?v=v1

## Describing Methods

You can add a description to API methods and namespaces.

```ruby
desc "Returns your public timeline."
get :public_timeline do
  Status.limit(20)
end
```

## Parameters

Request parameters are available through the `params` hash object. This includes `GET`, `POST`
and `PUT` parameters, along with any named parameters you specify in your route strings.

```ruby
get :public_timeline do
  Status.order(params[:sort_by])
end
```

Parameters are automatically populated from the request body on POST and PUT for form input, JSON and
XML content-types.

The request:

```
curl -d '{"text": "140 characters"}' 'http://localhost:9292/statuses' -H Content-Type:application/json -v
```

The Grape endpoint:

```ruby
post '/statuses' do
  Status.create!({ :text => params[:text] })
end
```

## Parameter Validation and Coercion

You can define validations and coercion options for your parameters using a `params` block.

```ruby
params do
  requires :id, type: Integer
  optional :text, type: String, regexp: /^[a-z]+$/
  group :media do
    requires :url
  end
end
put ':id' do
  # params[:id] is an Integer
end
```

When a type is specified an implicit validation is done after the coercion to ensure
the output type is the one declared.

Parameters can be nested using `group`. In the above example, this means
`params[:media][:url]` is required along with `params[:id]`.

### Namespace Validation and Coercion

Namespaces allow parameter definitions and apply to every method within the namespace.

```ruby
namespace :statuses do
  params do
    requires :user_id, type: Integer, desc: "A user ID."
  end
  namespace ":user_id" do
    desc "Retrieve a user's status."
    params do
      requires :status_id, type: Integer, desc: "A status ID."
    end
    get ":status_id" do
      User.find(params[:user_id]).statuses.find(params[:status_id])
    end
  end
end
```

### Custom Validators

```ruby
class AlphaNumeric < Grape::Validations::Validator
  def validate_param!(attr_name, params)
    unless params[attr_name] =~ /^[[:alnum:]]+$/
      throw :error, :status => 400, :message => "#{attr_name}: must consist of alpha-numeric characters"
    end
  end
end
```

```ruby
params do
  requires :text, :alpha_numeric => true
end
```

You can also create custom classes that take parameters.

```ruby
class Length < Grape::Validations::SingleOptionValidator
  def validate_param!(attr_name, params)
    unless params[attr_name].length <= @option
      throw :error, :status => 400, :message => "#{attr_name}: must be at the most #{@option} characters long"
    end
  end
end
```

```ruby
params do
  requires :text, :length => 140
end
```

### Validation Errors

When validation and coercion errors occur an exception of type `Grape::Exceptions::ValidationError` is raised.
If the exception goes uncaught it will respond with a status of 400 and an error message.
You can rescue a `Grape::Exceptions::ValidationError` and respond with a custom response.

```ruby
rescue_from Grape::Exceptions::ValidationError do |e|
    Rack::Response.new({
        'status' => e.status,
        'message' => e.message,
        'param' => e.param
    }.to_json, e.status)
end
```

## Headers

Headers are available through the `header` helper or the `env` hash object.

```ruby
get do
  content_type = header['Content-type']
  # ...
end
```

```ruby
get do
  error!('Unauthorized', 401) unless env['HTTP_SECRET_PASSWORD'] == 'swordfish'
  # ...
end
```

## Routes

Optionally, you can define requirements for your named route parameters using regular
expressions. The route will match only if all requirements are met.

```ruby
get ':id', :requirements => { :id => /[0-9]*/ } do
  Status.find(params[:id])
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

## Cookies

You can set, get and delete your cookies very simply using `cookies` method.

```ruby
class API < Grape::API

  get 'status_count' do
    cookies[:status_count] ||= 0
    cookies[:status_count] += 1
    { :status_count => cookies[:status_count] }
  end

  delete 'status_count' do
    { :status_count => cookies.delete(:status_count) }
  end

end
```

Use a hash-based syntax to set more than one value.

```ruby
cookies[:status_count] = {
    :value => 0,
    :expires => Time.tomorrow,
    :domain => '.twitter.com',
    :path => '/'
}

cookies[:status_count][:value] +=1
```

Delete a cookie with `delete`.

```ruby
cookies.delete :status_count
```

Specify an optional path.

```ruby
cookies.delete :status_count, :path => '/'
```

## Redirecting

You can redirect to a new url temporarily (302) or permanently (301).

```ruby
redirect "/statuses"
```

```ruby
redirect "/statuses", :permanent => true
```

## Allowed Methods

When you add a route for a resource, a route for the HTTP OPTIONS
method will also be added. The response to an OPTIONS request will
include an "Allow" header listing the supported methods.

```ruby
class API < Grape::API

  get '/rt_count' do
    { :rt_count => current_user.rt_count }
  end

  params do
    requires :value, :type => Integer, :desc => 'Value to add to the rt count.'
  end
  put '/rt_count' do
    current_user.rt_count += params[:value].to_i
    { :rt_count => current_user.rt_count }
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
error! "Access Denied", 401
```

You can also return JSON formatted objects by raising error! and passing a hash
instead of a message.

```ruby
error! { "error" => "unexpected error", "detail" => "missing widget" }, 500
```

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
  rescue_from ArgumentError, NotImplementedError
end
```

The error format will match the request format. See "Content-Types" below.

Custom error formatters for existing and additional types can be defined with a proc.

```ruby
class Twitter::API < Grape::API
  error_formatter :txt, lambda { |message, backtrace, options, env|
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

You can rescue all exceptions with a code block. The `rack_response` wrapper
automatically sets the default error code and content-type.

```ruby
class Twitter::API < Grape::API
  rescue_from :all do |e|
    rack_response({ :message => "rescued from #{e.class.name}" })
  end
end
```

You can also rescue specific exceptions with a code block and handle the Rack
response at the lowest level.

```ruby
class Twitter::API < Grape::API
  rescue_from :all do |e|
    Rack::Response.new([ e.message ], 500, { "Content-type" => "text/error" }).finish
  end
end
```

Or rescue specific exceptions.

```ruby
class Twitter::API < Grape::API
  rescue_from ArgumentError do |e|
    Rack::Response.new([ "ArgumentError: #{e.message}" ], 500)
  end
  rescue_from NotImplementedError do |e|
    Rack::Response.new([ "NotImplementedError: #{e.message}" ], 500)
  end
end
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

## API Formats

By default, Grape supports _XML_, _JSON_, and _TXT_ content-types. The default format is `:txt`.

Serialization takes place automatically. For example, you do not have to call `to_json` in each JSON API implementation.

Your API can declare which types to support by using `content_type`. Response format
is determined by the request's extension, an explicit `format` parameter in the query
string, or `Accept` header.

The following API will only respond to the JSON content-type and will not parse any other input than `application/json`,
'application/x-www-form-urlencoded', 'multipart/form-data', 'multipart/related' and 'multipart/mixed'. All other requests
will fail with an HTTP 406 error code.

```ruby
class Twitter::API < Grape::API
  format :json
end
```

If you combine `format` with `rescue_from :all`, errors will be rendered using the same format.
If you do not want this behavior, set the default error formatter with `default_error_formatter`.

```ruby
class Twitter::API < Grape::API
  format :json
  content_type :txt, "text/plain"
  default_error_formatter :txt
end
```

Custom formatters for existing and additional types can be defined with a proc.

```ruby
class Twitter::API < Grape::API
  content_type :xls, "application/vnd.ms-excel"
  formatter :xls, lambda { |object, env| object.to_xls }
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
  content_type :xls, "application/vnd.ms-excel"
  formatter :xls, XlsFormatter
end
```

Built-in formats are the following.

* `:json`: use object's `to_json` when available, otherwise call `MultiJson.dump`
* `:xml`: use object's `to_xml` when available, usually via `MultiXml`, otherwise call `to_s`
* `:txt`: use object's `to_txt` when available, otherwise `to_s`
* `:serializable_hash`: use object's `serializable_hash` when available, otherwise fallback to `:json`

Use `default_format` to set the fallback format when the format could not be determined from the `Accept` header.
See below for the order for choosing the API format.

```ruby
class Twitter::API < Grape::API
  default_format :json
end
```

The order for choosing the format is the following.

* Use the file extension, if specified. If the file is .json, choose the JSON format.
* Use the value of the `format` parameter in the query string, if specified.
* Use the format set by the `format` option, if specified.
* Attempt to find an acceptable format from the `Accept` header.
* Use the default format, if specified by the `default_format` option.
* Default to `:txt`.

## Content-type

Content-type is set by the formatter. You can override the content-type of the response at runtime
by setting the `Content-Type` header.

```ruby
class API < Grape::API
  get '/home_timeline_js' do
    content_type "application/javascript"
    "var statuses = ...;"
  end
end
```

## API Data Formats

Grape accepts and parses input data sent with the POST and PUT methods as described in the Parameters
section above. It also supports custom data formats. You must declare additional content-types via
`content_type` and optionally supply a parser via `parser` unless a parser is already available within
Grape to enable a custom format. Such a parser can be a function or a class.

Without a parser, data is available "as-is" and can be read with `env['rack.input'].read`.

The following example is a trivial parser that will assign any input with the "text/custom" content-type
to `:value`. The parameter will be available via `params[:value]` inside the API call.

```ruby
module CustomParser
  def self.call(object, env)
    { :value => object.to_s }
  end
end
```

```ruby
content_type :txt, "text/plain"
content_type :custom, "text/custom"
parser :custom, CustomParser

put "value" do
  params[:value]
end
```

You can invoke the above API as follows.

```
curl -X PUT -d 'data' 'http://localhost:9292/value' -H Content-Type:text/custom -v
```

## RESTful Model Representations

Grape supports a range of ways to present your data with some help from a generic `present` method,
which accepts two arguments: the object to be presented and the options associated with it. The options
hash may include `:with`, which defines the entity to expose.

### Grape Entities

Add the [grape-entity](https://github.com/agileanimal/grape-entity) gem to your Gemfile.
Please refer to the [grape-entity documentation](https://github.com/agileanimal/grape-entity/blob/master/README.markdown)
for more details.

The following example exposes statuses.

```ruby
module API

  module Entities
    class Status < Grape::Entity
      expose :user_name
      expose :text, :documentation => { :type => "string", :desc => "Status update text." }
      expose :ip, :if => { :type => :full }
      expose :user_type, user_id, :if => lambda{ |status, options| status.user.public? }
      expose :digest { |status, options| Digest::MD5.hexdigest(satus.txt) }
      expose :replies, :using => API::Status, :as => :replies
    end
  end

  class Statuses < Grape::API
    version 'v1'

    desc 'Statuses index', {
      :object_fields => API::Entities::Status.documentation
    }
    get '/statuses' do
      statuses = Status.all
      type = current_user.admin? ? :full : :default
      present statuses, with: API::Entities::Status, :type => type
    end
  end
end
```

In addition to separately organizing entities, it may be useful to put them as namespaced
classes underneath the model they represent.

```ruby
class Status
  def entity
    Status.new(self)
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

### Hypermedia

You can use any Hypermedia representer, including [Roar](https://github.com/apotonick/roar).
Roar renders JSON and works with the built-in Grape JSON formatter. Add `Roar::Representer::JSON`
into your models or call `to_json` explicitly in your API implementation.

### Rabl

You can use [Rabl](https://github.com/nesquena/rabl) templates with the help of the
[grape-rabl](https://github.com/LTe/grape-rabl) gem, which defines a custom Grape Rabl
formatter.

## Describing and Inspecting an API

Grape routes can be reflected at runtime. This can notably be useful for generating
documentation.

Grape exposes arrays of API versions and compiled routes. Each route
contains a `route_prefix`, `route_version`, `route_namespace`, `route_method`,
`route_path` and `route_params`. The description and the optional hash that
follows the API path may contain any number of keys and its values are also
accessible via dynamically-generated `route_[name]` functions.

```ruby
TwitterAPI::versions # yields [ 'v1', 'v2' ]
TwitterAPI::routes # yields an array of Grape::Route objects
TwitterAPI::routes[0].route_version # yields 'v1'
TwitterAPI::routes[0].route_description # etc.
```

## Current Route and Endpoint

It's possible to retrieve the information about the current route from within an API
call with `route`.

```ruby
class MyAPI < Grape::API
  desc "Returns a description of a parameter."
  params do
    requires :id, :type => Integer, :desc => "Identity."
  end
  get "params/:id" do
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

## Anchoring

Grape by default anchors all request paths, which means that the request URL
should match from start to end to match, otherwise a `404 Not Found` is
returned. However, this is sometimes not what you want, because it is not always
known upfront what can be expected from the call. This is because Rack-mount by
default anchors requests to match from the start to the end, or not at all.
Rails solves this problem by using a `:anchor => false` option in your routes.
In Grape this option can be used as well when a method is defined.

For instance when you're API needs to get part of an URL, for instance:

```ruby
class TwitterAPI < Grape::API
  namespace :statuses do
    get '/(*:status)', :anchor => false do

    end
  end
end
```

This will match all paths starting with '/statuses/'. There is one caveat though:
the `params[:status]` parameter only holds the first part of the request url.
Luckily this can be circumvented by using the described above syntax for path
specification and using the `PATH_INFO` Rack environment variable, using
`env["PATH_INFO"]`. This will hold everything that comes after the '/statuses/'
part.

## Writing Tests

You can test a Grape API with RSpec by making HTTP requests and examining the response.

### Writing Tests with Rack

Use `rack-test` and define your API as `app`.

```ruby
require 'spec_helper'

describe Twitter::API do
  include Rack::Test::Methods

  def app
    Twitter::API
  end

  describe Twitter::API do
    describe "GET /api/v1/statuses" do
      it "returns an empty array of statuses" do
        get "/api/v1/statuses"
        last_response.status.should == 200
        JSON.parse(last_response.body).should == []
      end
    end
    describe "GET /api/v1/statuses/:id" do
      it "returns a status by id" do
        status = Status.create!
        get "/api/v1/statuses/#{status.id}"
        last_response.body.should == status.to_json
      end
    end
  end
end
```

### Writing Tests with Rails

```ruby
require 'spec_helper'

describe Twitter::API do
  describe "GET /api/v1/statuses" do
    it "returns an empty array of statuses" do
      get "/api/v1/statuses"
      response.status.should == 200
      JSON.parse(response.body).should == []
    end
  end
  describe "GET /api/v1/statuses/:id" do
    it "returns a status by id" do
      status = Status.create!
      get "/api/v1/statuses/#{status.id}"
      response.body.should == status.to_json
    end
  end
end
```

In Rails, HTTP request tests would go into the `spec/request` group. You may want your API code to go into
`app/api` - you can match that layout under `spec` by adding the following in `spec/spec_helper.rb`.

```ruby
RSpec.configure do |config|
  config.include RSpec::Rails::RequestExampleGroup, :type => :request, :example_group => {
    :file_path => /spec\/api/
  }
end
```

## Reloading API Changes in Development

### Rails 3.x

Source: http://stackoverflow.com/questions/3282655/ruby-on-rails-3-reload-lib-directory-for-each-request/4368838#4368838

Create file `config/initializers/reload_lib.rb`

```ruby
if Rails.env.development?
  lib_reloader = ActiveSupport::FileUpdateChecker.new(Dir["app/api/**/*"]) do
    Rails.application.reload_routes!
  end

  ActionDispatch::Callbacks.to_prepare do
    lib_reloader.execute_if_updated
  end
end
```

In `config/application.rb`, add

```ruby
config.autoload_paths += %W(#{config.root}/app/api)
config.autoload_paths += Dir["#{config.root}/app/api/**/"]
```

## Performance Monitoring

Grape integrates with NewRelic via the [newrelic-grape](https://github.com/flyerhzm/newrelic-grape) gem.

## Contributing to Grape

Grape is work of dozens of contributors. You're encouraged to submit pull requests, propose
features and discuss issues.

* Fork the project
* Write tests for your new feature or a test that reproduces a bug
* Implement your feature or make a bug fix
* Add a line to `CHANGELOG.markdown` describing your change
* Commit, push and make a pull request. Bonus points for topic branches.

## License

MIT License. See LICENSE for details.

## Copyright

Copyright (c) 2010-2012 Michael Bleigh, and Intridea, Inc.
