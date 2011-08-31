# Grape
[![Build Status](http://travis-ci.org/intridea/grape.png)](http://travis-ci.org/intridea/grape)

Grape is a REST-like API micro-framework for Ruby. It is built to complement existing web application frameworks such as Rails and Sinatra by providing a simple DSL to easily provide APIs. It has built-in support for common conventions such as multiple formats, subdomain/prefix restriction, and versioning.

## Installation

Grape is available as a gem, to install it just install the gem:

    gem install grape
    
## Basic Usage

Grape APIs are Rack applications that are created by subclassing `Grape::API`. Below is a simple example showing some of the more common features of Grape in the context of recreating parts of the Twitter API.

    class Twitter::API < Grape::API
      version '1'
      
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
    end
    
This would create a Rack application that could be used like so (in a Rackup config.ru file):

    run Twitter::API
    
And would respond to the following routes:

    GET  /1/statuses/public_timeline(.json)
    GET  /1/statuses/home_timeline(.json)
    GET  /1/statuses/show/:id(.json)
    POST /1/statuses/update(.json)
    
Serialization takes place automatically. For more detailed usage information, please visit the [Grape Wiki](http://github.com/intridea/grape/wiki).
    
## Raising Errors

You can raise errors explicitly.

    error!("Access Denied", 401)

You can also return JSON formatted objects explicitly by raising error! and passing a hash instead of a message.

    error!({ "error" => "unexpected error", "detail" => "missing widget" }, 500)

## Exception Handling

Grape can be told to rescue all exceptions and instead return them in text or json formats.

    class Twitter::API < Grape::API
      rescue_from :all
    end

You can also rescue specific exceptions.

    class Twitter::API < Grape::API
      rescue_from ArgumentError, NotImplementedError
    end

The error format can be specified using `error_format`. Available formats are `:json` and `:txt` (default).

    class Twitter::API < Grape::API
      error_format :json
    end

You can rescue all exceptions with a code block. The `rack_response` wrapper automatically sets the default error code and content-type.

    class Twitter::API < Grape::API
      rescue_from :all do |e|
        rack_response({ :message => "rescued from #{e.class.name}" })
      end
    end

You can also rescue specific exceptions with a code block and handle the Rack response at the lowest level.

    class Twitter::API < Grape::API
      rescue_from :all do |e|
        Rack::Response.new([ e.message ], 500, { "Content-type" => "text/error" ).finish
      end
    end

## Writing Tests

You can test a Grape API with RSpec. Tests make HTTP requests, therefore they must go into the `spec/request` group. You may want your API code to go into `app/api` - you can match that layout under `spec` by adding the following in `spec/spec_helper.rb`.

    RSpec.configure do |config|
      config.include RSpec::Rails::RequestExampleGroup, :type => :request, :example_group => { 
        :file_path => /spec\/api/
      } 
    end

A simple RSpec API test makes a `get` request and parses the response.

    require 'spec_helper'

    describe Twitter::API do
      describe "GET /api/v1/statuses" do
        it "returns an empty array of statuses" do
          get "/api/v1/statuses"
          response.status.should == 200
          JSON.parse(response.body).should == []
        end
      end
    end

## Inspecting an API

Grape exposes arrays of API versions and compiled routes. Each route contains a `route_prefix`, `route_version`, `route_namespace`, `route_method`, `route_path` and `route_params`.

    class TwitterAPI < Grape::API      

      version 'v1'
      get "version" do 
        api.version
      end

      version 'v2'
      namespace "ns" do
        get "version" do
          api.version
        end
      end      

    end

    TwitterAPI::versions # yields [ 'v1', 'v2' ]
    TwitterAPI::routes # yields an array of Grape::Route objects
    TwitterAPI::routes[0].route_version # yields 'v1'

Grape also supports storing additional parameters with the route information. This can be useful for generating documentation. The optional hash that follows the API path may contain any number of keys and its values are also accessible via a dynamically-generated `route_[name]` function.

    class StringAPI < Grape::API
      get "split/:string", { :params => [ "token" ], :optional_params => [ "limit" ] } do 
        params[:string].split(params[:token], (params[:limit] || 0))
      end
    end

    StringAPI::routes[0].route_params # yields an array [ "string", "token" ]
    StringAPI::routes[0].route_optional_params # yields an array [ "limit" ]

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with Rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 Michael Bleigh and Intridea, Inc. See LICENSE for details.
