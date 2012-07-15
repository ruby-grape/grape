# Grape [![Build Status](http://travis-ci.org/intridea/grape.png?branch=frontier)](http://travis-ci.org/intridea/grape)

## What is Grape?

Grape is a REST-like API micro-framework for Ruby. It is built to complement
existing web application frameworks such as Rails and Sinatra by providing a
simple DSL to easily provide APIs. It has built-in support for common
conventions such as multiple formats, subdomain/prefix restriction, and
versioning.

## Project Tracking

* [Grape Google Group](http://groups.google.com/group/ruby-grape)
* [Grape Wiki](https://github.com/intridea/grape/wiki)

## Installation

Grape is available as a gem, to install it just install the gem:

    gem install grape

If you're using Bundler, add the gem to Gemfile.

    gem 'grape'

## Basic Usage

Grape APIs are Rack applications that are created by subclassing `Grape::API`.
Below is a simple example showing some of the more common features of Grape in
the context of recreating parts of the Twitter API.

``` ruby
class Twitter::API < Grape::API
  version 'v1', :using => :header, :vendor => 'twitter'

  helpers do
    def current_user
      @current_user ||= User.authorize!(env)
    end

    def authenticate!
      error!('401 Unauthorized', 401) unless current_user
    end
  end

  resource :statuses do
    get :public_timeline do
      Tweet.limit(20)
    end

    get :home_timeline do
      authenticate!
      current_user.home_timeline
    end

    get '/show/:id' do
      Tweet.find(params[:id])
    end

    post :update do
      authenticate!
      Tweet.create(
        :user => current_user,
        :text => params[:status]
      )
    end
  end

  resource :account do
    before { authenticate! }

    get '/private' do
      "Congratulations, you found the secret!"
    end
  end

end
```

Optionally, you can define requirements for your named route parameters using regular expressions. The route will match only if
all requirements are met.

```ruby
get '/show/:id', :requirements => { :id => /[0-9]*/ } do
  Tweet.find(params[:id])
end
```

## Mounting

The above sample creates a Rack application that can be run from a rackup *config.ru* file 
with `rackup`:

``` ruby
run Twitter::API
```

And would respond to the following routes:

    GET  /statuses/public_timeline(.json)
    GET  /statuses/home_timeline(.json)
    GET  /statuses/show/:id(.json)
    POST /statuses/update(.json)

In a Rails application, modify *config/routes*:

``` ruby
mount Twitter::API => "/"
```

You can mount multiple API implementations inside another one.

```ruby
class Twitter::API < Grape::API
  mount Twitter::APIv1
  mount Twitter::APIv2
end
```

## Versioning

There are three strategies in which clients can reach your API's endpoints: `:header`, `:path` and `:param`. The default strategy is `:header`.


### Header

```ruby
version 'v1', :using => :header
```

Using this versioning strategy, clients should pass the desired version in the HTTP Accept head. 

    curl -H Accept=application/vnd.twitter-v1+json http://localhost:9292/statuses/public_timeline

By default, the first matching version is used when no Accept header is
supplied. This behavior is similar to routing in Rails. To circumvent this default behavior,
one could use the `:strict` option. When this option is set to `true`, a `404 Not found` error
is returned when no correct Accept header is supplied.

### Path

``` ruby
version 'v1', :using => :path
```

Using this versioning strategy, clients should pass the desired version in the URL.

    curl -H http://localhost:9292/v1/statuses/public_timeline

Serialization takes place automatically. 

### Param

```ruby
version 'v1', :using => :param
```

Using this versioning strategy, clients should pass the desired version as a request parameter, either in the URL query string or in the request body. 

    curl -H http://localhost:9292/events?apiver=v1

The default name for the query parameter is 'apiver' but can be specified using the :parameter option.

```ruby
version 'v1', :using => :param, :parameter => "v"
```

    curl -H http://localhost:9292/events?v=v1

## Parameters

Parameters are available through the `params` hash object. This includes `GET` and `POST` parameters, 
along with any named parameters you specify in your route strings.

```ruby
get do
    Article.order(params[:sort_by])
end
```

Parameters are also populated from the request body on POST and PUT for JSON and XML content-types.

The Request:

```curl -d '{"some_key": "some_value"}' 'http://localhost:9292/json_endpoint' -H Content-Type:application/json -v```

The Grape Endpoint:

```ruby
post '/json_endpoint' do
    params[:some_key]
end
```

## Validations

You can define validations and coercion option for your attributes:

```ruby
params do
  required :id, type: Integer
  optional :name, type: String, regexp: /^[a-z]+$/
end

get ':id' do
  # params[:id] is an Integer
end
```

When a type is specified an implicit validation is done after the coercion to ensure the output type is what you asked.


## Headers

Headers are available through the `env` hash object.

```ruby
get do
    error! 'Unauthorized', 401 unless env['HTTP_SECRET_PASSWORD'] == 'swordfish'
    ...
end
```

## Helpers

You can define helper methods that your endpoints can use with the `helpers`
macro by either giving a block or a module:

``` ruby
module MyHelpers
  def say_hello(user)
    "hey there #{user.name}"
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
  helpers MyHelpers

  get '/hello' do
    # helpers available in your endpoint and filters
    say_hello(current_user)
  end
end
```

## Cookies

You can set, get and delete your cookies very simply using `cookies` method:

``` ruby
class API < Grape::API
  get '/counter' do
    cookies[:counter] ||= 0
    cookies[:counter] += 1
    { :counter => cookies[:counter] }
  end

  delete '/counter' do
    { :result => cookies.delete(:counter) }
  end
end
```

To set more than value use hash-based syntax:

``` ruby
cookies[:counter] = {
    :value => 0,
    :expires => Time.tomorrow,
    :domain => '.example.com',
    :path => '/'
}
cookies[:counter][:value] +=1
```
## Redirect

You can redirect to a new url

``` ruby
redirect "/new_url"
```

use permanent redirect

``` ruby
redirect "/new_url", :permanent => true
```

## Raising Errors

You can raise errors explicitly.

``` ruby
error!("Access Denied", 401)
```

You can also return JSON formatted objects explicitly by raising error! and
passing a hash instead of a message.

``` ruby
error!({ "error" => "unexpected error", "detail" => "missing widget" }, 500)
```

## Exception Handling

Grape can be told to rescue all exceptions and instead return them in
text or json formats.

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

The error format can be specified using `error_format`. Available formats are
`:json` and `:txt` (default).

``` ruby
class Twitter::API < Grape::API
  error_format :json
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
available in the endpoint context:

``` ruby
class API < Grape::API
  helpers do
    def logger
      API.logger
    end
  end
  get '/hello' do
    logger.info "someone said hello"
    "hey there"
  end
end
```

You can also set your own logger:

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
  get '/hello' do
    logger.warning "someone said hello"
    "hey there"
  end
end
```

## Content-Types

By default, Grape supports _XML_, _JSON_, _Atom_, _RSS_, and _text_ content-types.
Your API can declare additional types to support. Response format is determined by the
request's extension or `Accept` header.

``` ruby
class Twitter::API < Grape::API
  content_type :xls, "application/vnd.ms-excel"
end
```

You can also set the default format. The order for choosing the format is the following.

* Use the file extension, if specified. If the file is .json, choose the JSON format.
* Use the format, if specified by the `format` option.
* Attempt to find an acceptable format from the `Accept` header.
* Use the default format, if specified by the `default_format` option.
* Default to `:txt` otherwise.

``` ruby
class Twitter::API < Grape::API
  format :json
  default_format :json
end
```

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
      resonse.body.should == status.to_json
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

## Reusable Responses with Entities

Entities are a reusable means for converting Ruby objects to API responses.
Entities can be used to conditionally include fields, nest other entities, and build
ever larger responses, using inheritance.

### Defining Entities

Entities inherit from Grape::Entity, and define a simple DSL. Exposures can use
runtime options to determine which fields should be visible, these options are
available to :if, :unless, and :proc. The option keys :version and :collection
will always be defined. The :version key is defined as api.version. The
:collection key is boolean, and defined as true if the object presented is an
array.

  * `expose SYMBOLS`
    * define a list of fields which will always be exposed
  * `expose SYMBOLS, HASH`
    * HASH keys include :if, :unless, :proc, :as, :using, :format_with, :documentation
      * :if and :unless accept hashes (passed during runtime) or procs (arguments are object and options)
  * `expose SYMBOL, {:format_with => :formatter}`
    * expose a value, formatting it first
    * :format_with can only be applied to one exposure at a time
  * `expose SYMBOL, {:as => "alias"}`
    * Expose a value, changing its hash key from SYMBOL to alias
    * :as can only be applied to one exposure at a time
  * `expose SYMBOL BLOCK`
    * block arguments are object and options
    * expose the value returned by the block
    * block can only be applied to one exposure at a time

``` ruby
module API
  module Entities
    class User < Grape::Entity
      expose :first_name, :last_name
      expose :field, :documentation => {:type => "string", :desc => "words go here"}
      expose :email, :if => {:type => :full}
      expose :user_type, user_id, :if => lambda{|user,options| user.confirmed?}
      expose(:name){|user,options| [user.first_name, user.last_name].join(' ')}
      expose :latest_status, :using => API::Status, :as => :status
    end
  end
end

module API
  module Entities
    class UserDetailed < API::Entities::User
      expose :account_id
    end
  end
end
```

### Using Entities

Once an entity is defined, it can be used within endpoints, by calling #present. The #present
method accepts two arguments, the object to be presented and the options associated with it. The
options hash must always include :with, which defines the entity to expose.

If the entity includes documentation it can be included in an endpoint's description.

``` ruby
module API
  class Users < Grape::API
    version 'v1'

    desc 'User index', {
      :object_fields => API::Entities::User.documentation
    }
    get '/users' do
      @users = User.all
      type = current_user.admin? ? :full : :default
      present @users, with: API::Entities::User, :type => type
    end
  end
end
```

### Caveats

Entities with duplicate exposure names and conditions will silently overwrite one another.
In the following example, when object#check equals "foo", only afield will be exposed. 
However, when object#check equals "bar" both bfield and foo will be exposed.

```ruby
module API
  module Entities
    class User < Grape::Entity
      expose :afield, :foo, :if => lambda{|object,options| object.check=="foo"}
      expose :bfield, :foo, :if => lambda{|object,options| object.check=="bar"}
    end
  end
end
```

This can be problematic, when you have mixed collections. Using #respond_to? is safer.

```ruby
module API
  module Entities
    class User < Grape::Entity
      expose :afield, :if => lambda{|object,options| object.check=="foo"}
      expose :bfield, :if => lambda{|object,options| object.check=="bar"}
      expose :foo, :if => lambda{object,options| object.respond_to?(:foo)}
    end
  end
end
```

## Describing and Inspecting an API

Grape lets you add a description to an API along with any other optional
elements that can also be inspected at runtime.
This can be useful for generating documentation. If the response 
requires documentation, consider using an entity.

``` ruby
class TwitterAPI < Grape::API

  version 'v1'

  desc "Retrieves the API version number."
  get "version" do
    api.version
  end

  desc "Reverses a string.", { :params =>
    { "s" => { :desc => "string to reverse", :type => "string" }}
  }
  get "reverse" do
    params[:s].reverse
  end
end
```

Grape then exposes arrays of API versions and compiled routes. Each route
contains a `route_prefix`, `route_version`, `route_namespace`, `route_method`,
`route_path` and `route_params`. The description and the optional hash that
follows the API path may contain any number of keys and its values are also
accessible via dynamically-generated `route_[name]` functions.

``` ruby
TwitterAPI::versions # yields [ 'v1', 'v2' ]
TwitterAPI::routes # yields an array of Grape::Route objects
TwitterAPI::routes[0].route_version # yields 'v1'
TwitterAPI::routes[0].route_description # yields [ { "s" => { :desc => "string to reverse", :type => "string" }} ]
```

Parameters can also be tagged to the method declaration itself.

``` ruby
class StringAPI < Grape::API
  get "split/:string", { :params => { "token" => "a token" }, :optional_params => { "limit" => "the limit" } } do
    params[:string].split(params[:token], (params[:limit] || 0))
  end
end

StringAPI::routes[0].route_params # yields a hash {"string" => "", "token" => "a token"}
StringAPI::routes[0].route_optional_params # yields a hash {"limit" => "the limit"}
```

It's possible to retrieve the information about the current route from within an API call with `route`.

``` ruby
class MyAPI < Grape::API
  desc "Returns a description of a parameter.", { :params => { "id" => "a required id" } }
  get "params/:id" do
    route.route_params[params[:id]] # returns "a required id"
  end
end
```

You can use this information to create a helper that will check if the request has
all required parameters:

``` ruby
class MyAPI < Grape::API

  helpers do
    def validate_request!
      # skip validation if no parameter is declared
      return unless route.route_params
      route.route_params.each do |k, v|
        if !params.has_key? k
          error!("Missing field: #{k}", 400)
        end
      end
    end
  end

  before { validate_request! }

  desc "creates a new item resource", :params => { :name => 'name is a required parameter' }
  post :items do
    ...
  end
end
```

## Anchoring

Grape by default anchors all request paths, which means that the request URL
should match from start to end to match, otherwise a `404 Not Found` is
returned.
However, this is sometimes not what you want, because it is not always known up
front what can be expected from the call.
This is because Rack-mount by default anchors requests to match from the start
to the end, or not at all. Rails solves this problem by using a `:anchor =>
false` option in your routes.
In Grape this option can be used as well when a method is defined.

For instance when you're API needs to get part of an URL, for instance:

``` ruby
class UrlAPI < Grape::API
  namespace :urls do
    get '/(*:url)', :anchor => false do
      some_data
    end
  end
end
```

This will match all paths starting with '/urls/'. There is one caveat though:
the `params[:url]` parameter only holds the first part of the request url.
Luckily this can be circumvented by using the described above syntax for path
specification and using the `PATH_INFO` Rack environment variable, using
`env["PATH_INFO"]`. This will hold everything that comes after the '/urls/'
part.

## Note on Patches/Pull Requests

* Fork the project
* Write tests for your new feature or a test that reproduces a bug
* Implement your feature or make a bug fix
* Do not mess with Rakefile, version or history
* Commit, push and make a pull request. Bonus points for topical branches.

## License

MIT License. See LICENSE for details.

## Copyright

Copyright (c) 2010-2012 Michael Bleigh and Intridea, Inc.

