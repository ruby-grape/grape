# frozen_string_literal: true

module Grape
  module Middleware
    module Auth
      class Base < Grape::Middleware::Base
        def initialize(app, **options)
          super
          return unless options.key?(:type)

          @auth_strategy = Grape::Middleware::Auth::Strategies[options[:type]]
          raise Grape::Exceptions::UnknownAuthStrategy.new(strategy: options[:type]) unless @auth_strategy
        end

        # Base#call copies the middleware per request so #call! can keep the
        # env in an ivar, and all that reads it is the strategy's block, to find
        # the endpoint that checks the credentials. The block takes the
        # endpoint from the env it was built for instead, so the request is
        # answered by the one instance the stack built.
        def call(env)
          authenticate(env).to_a
        end

        def call!(env)
          @env = env
          authenticate(env)
        end

        private

        def authenticate(env)
          @auth_strategy.create(app, options) do |*args|
            env[Grape::Env::API_ENDPOINT].instance_exec(*args, &options[:proc])
          end.call(env)
        end
      end
    end
  end
end
