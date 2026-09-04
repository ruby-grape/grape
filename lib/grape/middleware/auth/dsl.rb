# frozen_string_literal: true

module Grape
  module Middleware
    module Auth
      module DSL
        def auth(type = nil, **options, &block)
          return inheritable_setting.auth unless type

          inheritable_setting.auth = { type: type.to_sym, proc: block }.merge!(options)
          use Grape::Middleware::Auth::Base, inheritable_setting.auth
        end

        # Add HTTP Basic authorization to the API.
        #
        # @param options [Hash] a hash of options
        # @option options [String] :realm "API Authorization" the HTTP Basic realm
        def http_basic(**options, &)
          options[:realm] ||= 'API Authorization'
          auth(:http_basic, **options, &)
        end
      end
    end
  end
end
