# frozen_string_literal: true

module Grape
  class Railtie < ::Rails::Railtie
    initializer 'grape.deprecator' do |app|
      app.deprecators[:grape] = Grape.deprecator
    end

    # Rails builds its own routes' router at boot when it eager loads; compile
    # the APIs mounted in them then too, rather than on the first request each
    # process answers.
    config.after_routes_loaded do |app|
      compile_mounted_apis(app.routes) if app.config.eager_load
    end

    class << self
      private

      def compile_mounted_apis(route_set)
        route_set.routes.each do |route|
          endpoint = route.app
          next compile_mounted_apis(endpoint.rack_app.routes) if endpoint.engine?

          rack_app = endpoint.rack_app
          rack_app.compile! if rack_app.is_a?(Class) && rack_app < Grape::API
        end
      end
    end
  end
end
