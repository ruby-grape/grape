# frozen_string_literal: true

module Grape
  module Middleware
    class Globals < Base
      def before
        request = Grape::Request.new(@env, build_params_with: @options[:build_params_with])
        @env[Grape::Util::Env::GRAPE_REQUEST] = request
        @env[Grape::Util::Env::GRAPE_REQUEST_HEADERS] = request.headers
        @env[Grape::Util::Env::GRAPE_REQUEST_PARAMS] = request.params if @env[Grape::Util::Env::RACK_INPUT]
      end
    end
  end
end
