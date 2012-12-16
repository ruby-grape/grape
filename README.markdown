![grape logo](https://github.com/intridea/grape/wiki/grape_logo.png)

## What is Grape?

Grape is a REST-like API micro-framework for Ruby. It's designed to run on Rack
or complement existing web application frameworks such as Rails and Sinatra by
providing a simple DSL to easily develop RESTful APIs. It has built-in support
for common conventions, including multiple formats, subdomain/prefix restriction,
content negotiation, versioning and much more.

[![Build Status](https://travis-ci.org/intridea/grape.png?branch=master)](http://travis-ci.org/intridea/grape)

## Project Tracking

* [Grape Google Group](http://groups.google.com/group/ruby-grape)
* [Grape Wiki](https://github.com/intridea/grape/wiki)

## Stable Release

You're reading the documentation for the next release of Grape, which should be 0.2.3.
The current stable release is [0.2.2](https://github.com/intridea/grape/blob/v0.2.2/README.markdown).

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

``` ruby
class Twitter::API < Grape::API
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
      Tweet.limit(20)
    end

    desc "Return a personal timeline."
    get :home_timeline do
      authenticate!
      current_user.tweets.limit(20)
    end

    desc "Return a tweet."
    params do
      requires :id, :type => Integer, :desc => "Tweet id."
    end
    get ':id' do
      Tweet.find(params[:id])
    end

    desc "Create a tweet."
    params do
      requires :status, :type => String, :desc => "Your status."
    end
    post do
      authenticate!
      Tweet.create!({
        :user => current_user,
        :text => params[:status]
      })
    end

    desc "Update a tweet."
    params do
      requires :id, :type => String, :desc => "Tweet ID."
      requires :status, :type => String, :desc => "Your status."
    end
    put ':id' do
      authenticate!
      current_user.tweets.find(params[:id]).update({
        :user => current_user,
        :text => params[:status]
      })
    end

    desc "Delete a tweet."
    params do
      requires :id, :type => String, :desc => "Tweet ID."
    end
    delete ':id' do
      authenticate!
      current_user.tweets.find(params[:id]).destroy
    end

  end

end
```

## Mounting

### Rack

The above sample creates a Rack application that can be run from a rackup *config.ru* file
with `rackup`:

``` ruby
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

``` ruby
mount Twitter::API => "/"
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

``` ruby
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

``` ruby
desc "Returns your public timeline."
get :public_timeline do
  Tweet.limit(20)
end
```

## Parameters

Request parameters are available through the `params` hash object. This includes `GET` and `POST` parameters,
along with any named parameters you specify in your route strings.

```ruby
get :public_timeline do
  Tweet.order(params[:sort_by])
end
```

Parameters are also populated from the request body on POST and PUT for JSON and XML content-types.

The Request:

```curl -d '{"text": "140 characters"}' 'http://localhost:9292/statuses' -H Content-Type:application/json -v```

The Grape Endpoint:

```ruby
post '/statuses' do
  Tweet.create!({ :text => params[:text] })
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
    desc "Retrieve a user's tweet."
    params do
      requires :tweet_id, type: Integer, desc: "A tweet ID."
    end
    get ":tweet_id" do
      User.find(params[:user_id]).tweets.find(params[:tweet_id])
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
    ...
end
```

```ruby
get do
    error!('Unauthorized', 401) unless env['HTTP_SECRET_PASSWORD'] == 'swordfish'
    ...
end
```

## Routes

Optionally, you can define requirements for your named route parameters using regular
expressions. The route will match only if all requirements are met.

```ruby
get ':id', :requirements => { :id => /[0-9]*/ } do
  Tweet.find(params[:id])
end
```

## Helpers

You can define helper methods that your endpoints can use with the `helpers`
macro by either giving a block or a module.

``` ruby
module TweetHelpers
  def user_info(user)
    "#{user} has tweeted #{user.tweets} tweet(s)"
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
  helpers TweetHelpers

  get 'info' do
    # helpers available in your endpoint and filters
    user_info(current_user)
  end
end
```

## Cookies

You can set, get and delete your cookies very simply using `cookies` method.

``` ruby
class API < Grape::API

  get 'tweet_count' do
    cookies[:tweet_count] ||= 0
    cookies[:tweet_count] += 1
    { :tweet_count => cookies[:tweet_count] }
  end

  delete 'tweet_count' do
    { :tweet_count => cookies.delete(:tweet_count) }
  end

end
```

Use a hash-based syntax to set more than one value.

``` ruby
cookies[:tweet_count] = {
    :value => 0,
    :expires => Time.tomorrow,
    :domain => '.twitter.com',
    :path => '/'
}

cookies[:tweet_count][:value] +=1
```

## Redirecting

You can redirect to a new url temporarily (302) or permanently (301).

``` ruby
redirect "/statuses"
```

``` ruby
redirect "/statuses", :permanent => true
```

## Allowed Methods

When you add a route for a resource, a route for the HTTP OPTIONS
method will also be added. The response to an OPTIONS request will
include an "Allow" header listing the supported methods.

``` ruby
class API < Grape::API

  get '/retweet_count' do
    { :retweet_count => current_user.retweet_count }
  end

  params do
    requires :value, :type => Integer, :desc => 'Value to add to the retweet count.'
  end
  put '/retweet_count' do
    current_user.retweet_count += params[:value].to_i
    { :retweet_count => current_user.retweet_count }
  end
end
```

``` shell
curl -v -X OPTIONS http://localhost:3000/retweet_count

> OPTIONS /retweet_count HTTP/1.1
>
< HTTP/1.1 204 No Content
< Allow: OPTIONS, GET, PUT
```

If a request for a resource is made with an unsupported HTTP method, an
HTTP 405 (Method Not Allowed) response will be returned.

``` shell
curl -X DELETE -v http://localhost:3000/retweet_count/

> DELETE /retweet_count/ HTTP/1.1
> Host: localhost:3000
>
< HTTP/1.1 405 Method Not Allowed
< Allow: OPTIONS, GET, PUT
```

## Raising Exceptions

You can abort the execution of an API method by raising errors with `error!`.

``` ruby
error!("Access Denied", 401)
```

You can also return JSON formatted objects by raising error! and passing a hash
instead of a message.

``` ruby
error!({ "error" => "unexpected error", "detail" => "missing widget" }, 500)
```

## Exception Handling

Grape can be told to rescue all exceptions and return them in txt or json formats.

``` ruby
class Twitter::API < Grape::API
  rescue_from :all
end
```

You can also rescue specific exceptions.

``` ruby
class Twitter::API < Grape::API
  rescue_from ArgumentError, NotImplementedError
end
```

The error format will match the request format. See "Content-Types" below.

Custom error formatters for existing and additional types can be defined with a proc.

``` ruby
class Twitter::API < Grape::API
  error_formatter :txt, lambda { |message, backtrace, options| "error: #{message} from #{backtrace}" }
end
```

You can also use a module or class.

``` ruby
module CustomFormatter
  def self.call(message, backtrace, options)
    { message: message, backtrace: backtrace }
  end
end

class Twitter::API < Grape::API
  error_formatter :custom, CustomFormatter
end
```

You can rescue all exceptions with a code block. The `rack_response` wrapper
automatically sets the default error code and content-type.

``` ruby
class Twitter::API < Grape::API
  rescue_from :all do |e|
    rack_response({ :message => "rescued from #{e.class.name}" })
  end
end
```

You can also rescue specific exceptions with a code block and handle the Rack
response at the lowest level.

``` ruby
class Twitter::API < Grape::API
  rescue_from :all do |e|
    Rack::Response.new([ e.message ], 500, { "Content-type" => "text/error" }).finish
  end
end
```

Or rescue specific exceptions.

``` ruby
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

``` ruby
class API < Grape::API
  helpers do
    def logger
      API.logger
    end
  end
  post '/statuses' do
    ...
    logger.info "#{current_user} has tweeted"
  end
end
```

You can also set your own logger.

``` ruby
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
    logger.warning "#{current_user} has tweeted"
  end
end
```

## Content-Types

By default, Grape supports _XML_, _JSON_, _Atom_, _RSS_, and _text_ content-types.
Serialization takes place automatically.

Your API can declare which types to support by using `content_type`. Response format
is determined by the request's extension, an explicit `format` parameter in the query
string, or `Accept` header.

The following API will only respond to the JSON content-type. All other requests will
fail with an HTTP 406 error code.

``` ruby
class Twitter::API < Grape::API
  format :json
  content_type :json, "application/json"
end
```

Custom formatters for existing and additional types can be defined with a proc.

``` ruby
class Twitter::API < Grape::API
  content_type :xls, "application/vnd.ms-excel"
  formatter :xls, lambda { |object| object.to_xls }
end
```

You can also use a module or class.

``` ruby
module XlsFormatter
  def self.call(object)
    object.to_xls
  end
end

class Twitter::API < Grape::API
  content_type :xls, "application/vnd.ms-excel"
  formatter :xls, XlsFormatter
end
```

The default format is `:txt`. You can set the preferred format for an API that
supports multiple formats with `format`.

``` ruby
class Twitter::API < Grape::API
  format :json
end
```

You can set the fallback, default format with `default_format`.

``` ruby
class Twitter::API < Grape::API
  default_format :json
end
```

Available formats are the following.

* `:json`: use object's `to_json` when available, otherwise call `MultiJson.dump`
* `:xml`: use object's `to_xml` when available, usually via `MultiXml`, otherwise call `to_s`
* `:txt`: use object's `to_txt` when available, otherwise `to_s`
* `:serializable_hash`: use object's `serializable_hash` when available, otherwise fallback to `:json`

The order for choosing the format is the following.

* Use the file extension, if specified. If the file is .json, choose the JSON format.
* Use the value of the `format` parameter in the query string, if specified.
* Use the format set by the `format` option, if specified.
* Attempt to find an acceptable format from the `Accept` header.
* Use the default format, if specified by the `default_format` option.
* Default to `:txt` otherwise.

You can override the content-type of the response by setting the `Content-Type` header.

``` ruby
class API < Grape::API
  get '/home_timeline_js' do
    content_type "application/javascript"
    "var tweets = ...;"
  end
end
```

## Reusable Responses with Entities

Entities are a reusable means for converting Ruby objects to API responses.
Entities can be used to conditionally include fields, nest other entities, and build
ever larger responses, using inheritance.

### Defining Entities

Entities inherit from Grape::Entity, and define a simple DSL. Exposures can use
runtime options to determine which fields should be visible, these options are
available to `:if`, `:unless`, and `:proc`. The option keys `:version` and `:collection`
will always be defined. The `:version` key is defined as `api.version`. The
`:collection` key is boolean, and defined as `true` if the object presented is an
array.

  * `expose SYMBOLS`
    * define a list of fields which will always be exposed
  * `expose SYMBOLS, HASH`
    * HASH keys include `:if`, `:unless`, `:proc`, `:as`, `:using`, `:format_with`, `:documentation`
      * `:if` and `:unless` accept hashes (passed during runtime) or procs (arguments are object and options)
  * `expose SYMBOL, { :format_with => :formatter }`
    * expose a value, formatting it first
    * `:format_with` can only be applied to one exposure at a time
  * `expose SYMBOL, { :as => "alias" }`
    * Expose a value, changing its hash key from SYMBOL to alias
    * `:as` can only be applied to one exposure at a time
  * `expose SYMBOL BLOCK`
    * block arguments are object and options
    * expose the value returned by the block
    * block can only be applied to one exposure at a time

``` ruby
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
end

module API
  module Entities
    class StatusDetailed < API::Entities::Status
      expose :internal_id
    end
  end
end
```

#### Using the Exposure DSL

Grape ships with a DSL to easily define entities within the context
of an existing class:

```ruby
class Status
  include Grape::Entity::DSL

  entity :text, :user_id do
    expose :detailed, if: :conditional
  end
end
```

The above will automatically create a `Status::Entity` class and define properties on it according
to the same rules as above. If you only want to define simple exposures you don't have to supply
a block and can instead simply supply a list of comma-separated symbols.

### Using Entities

Once an entity is defined, it can be used within endpoints, by calling `present`. The `present`
method accepts two arguments, the object to be presented and the options associated with it. The
options hash must always include `:with`, which defines the entity to expose.

If the entity includes documentation it can be included in an endpoint's description.

``` ruby
module API
  class Statuses < Grape::API
    version 'v1'

    desc 'Statuses index', {
      :object_fields => API::Entities::Status.documentation
    }
    get '/statues' do
      statuses = Status.all
      type = current_user.admin? ? :full : :default
      present statues, with: API::Entities::Status, :type => type
    end
  end
end
```

### Entity Organization

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
use it to present your models. In this example, if you added `present User.new` to your endpoint,
Grape would automatically detect that there is a `Status::Entity` class and use that as the
representative entity. This can still be overridden by using the `:with` option or an explicit
`represents` call.

### Caveats

Entities with duplicate exposure names and conditions will silently overwrite one another.
In the following example, when `object.check` equals "foo", only `field_a` will be exposed.
However, when `object.check` equals "bar" both `field_b` and `foo` will be exposed.

```ruby
module API
  module Entities
    class Status < Grape::Entity
      expose :field_a, :foo, :if => lambda { |object, options| object.check == "foo" }
      expose :field_b, :foo, :if => lambda { |object, options| object.check == "bar" }
    end
  end
end
```

This can be problematic, when you have mixed collections. Using `respond_to?` is safer.

```ruby
module API
  module Entities
    class Status < Grape::Entity
      expose :field_a, :if => lambda { |object, options| object.check == "foo" }
      expose :field_b, :if => lambda { |object, options| object.check == "bar" }
      expose :foo, :if => lambda { |object, options| object.respond_to?(:foo) }
    end
  end
end
```

## Describing and Inspecting an API

Grape routes can be reflected at runtime. This can notably be useful for generating
documentation.

Grape exposes arrays of API versions and compiled routes. Each route
contains a `route_prefix`, `route_version`, `route_namespace`, `route_method`,
`route_path` and `route_params`. The description and the optional hash that
follows the API path may contain any number of keys and its values are also
accessible via dynamically-generated `route_[name]` functions.

``` ruby
TwitterAPI::versions # yields [ 'v1', 'v2' ]
TwitterAPI::routes # yields an array of Grape::Route objects
TwitterAPI::routes[0].route_version # yields 'v1'
TwitterAPI::routes[0].route_description # etc.
```

It's possible to retrieve the information about the current route from within an API
call with `route`.

``` ruby
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

## Anchoring

Grape by default anchors all request paths, which means that the request URL
should match from start to end to match, otherwise a `404 Not Found` is
returned. However, this is sometimes not what you want, because it is not always
known upfront what can be expected from the call. This is because Rack-mount by
default anchors requests to match from the start to the end, or not at all.
Rails solves this problem by using a `:anchor => false` option in your routes.
In Grape this option can be used as well when a method is defined.

For instance when you're API needs to get part of an URL, for instance:

``` ruby
class TwitterAPI < Grape::API
  namespace :statues do
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
        JSON.parse(response.body).should == []
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

``` ruby
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

## Contributing to Grape

Grape is work of dozens of contributors. You're encouraged to submit pull requests, propose
features and discuss issues.

* Fork the project
* Write tests for your new feature or a test that reproduces a bug
* Implement your feature or make a bug fix
* Do not mess with Rakefile, version or history
* Commit, push and make a pull request. Bonus points for topic branches.

## License

MIT License. See LICENSE for details.

## Copyright

Copyright (c) 2010-2012 Michael Bleigh, and Intridea, Inc.
