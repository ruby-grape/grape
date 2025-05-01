# frozen_string_literal: true

module Grape
  module Middleware
    module Auth
      class Base
        attr_accessor :options, :app, :env

        def initialize(app, **options)
          @app = app
          @options = options
        end

        def call(env)
          dup._call(env)
        end

        def _call(env)
          self.env = env
          return app.call(env) unless options.key?(:type)

          strategy_info = Grape::Middleware::Auth::Strategies[options[:type]]
          throw :error, status: 401, message: 'API Authorization Failed.' if strategy_info.blank?

          strategy_info.create(@app, options) do |*args|
            env[Grape::Env::API_ENDPOINT].instance_exec(*args, &options[:proc])
          end.call(env)
        end
      end
    end
  end
end
