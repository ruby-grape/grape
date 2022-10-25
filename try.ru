require 'rubygems'
gem 'grape', '1.7.0'
require 'grape'



module Twitter
  class API < Grape::API
    version 'v1', using: :header, vendor: 'twitter'
    format :json
    prefix :api

    desc 'Create T'
    params do
      optional :device_type, type: String, desc: 'device_type', values: ['type1', 'type2']
      given device_type: ->(val) { val == 'type1' } do
        requires :device_config, type: Hash do
          requires :rtsp, type: String
        end
      end
      given device_type: ->(val) { val == 'type2' } do
        requires :device_config, type: Hash do
          requires :number, type: Integer
        end
      end
    end
    post do
      puts declared(params)
      puts declared(params, include_missing: false)
      puts declared(params, include_missing: false, include_not_dependent: false)
    end
  end
end

Twitter::API.compile!
run Twitter::API
