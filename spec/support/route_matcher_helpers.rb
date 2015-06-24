module Spec
  module Support
    module RouteMatcherHelpers
      def self.api
        Class.new(Grape::API) do
          version 'v1'
          prefix 'api'
          format 'json'

          get 'ping' do
            'pong'
          end

          resource :cats do
            get '/' do
              %w(cats cats cats)
            end

            route_param :id do
              get do
                'cat'
              end
            end
          end

          route :any, '*path' do
            'catch-all route'
          end
        end
      end
    end
  end
end
