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

## Inspecting an API

Grape exposes arrays of API versions and compiled routes. Each route contains a prefix, version, namespace, method and path.

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

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with Rakefile, version, or history. (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 Michael Bleigh and Intridea, Inc. See LICENSE for details.
