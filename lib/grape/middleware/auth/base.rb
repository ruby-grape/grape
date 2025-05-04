# frozen_string_literal: true

module Grape
  module Middleware
    module Auth
      class Base < Grape::Middleware::Base
        def initialize(app, **options)
          super
          @auth_strategy = Grape::Middleware::Auth::Strategies[options[:type]].tap do |auth_strategy|
            raise Grape::Exceptions::UnknownAuthStrategy.new(strategy: options[:type]) unless auth_strategy
          end
        end

        def call!(env)
          @env = env
          @auth_strategy.create(app, options) do |*args|
            context.instance_exec(*args, &options[:proc])
          end.call(env)
        end
      end
    end
  end
end
