require 'rack/auth/basic'

module Grape
  module Middleware
    module Auth
      module DSL
        # Add an authentication type to the API. Currently
        # only `:http_basic`, `:http_digest` are supported.
        def auth(type = nil, options = {}, &block)
          if type
            set(:auth, { type: type.to_sym, proc: block }.merge(options))
            use Grape::Middleware::Auth::Base, settings[:auth]
          else
            settings[:auth]
          end
        end

        # Add HTTP Basic authorization to the API.
        #
        # @param [Hash] options A hash of options.
        # @option options [String] :realm "API Authorization" The HTTP Basic realm.
        def http_basic(options = {}, &block)
          options[:realm] ||= "API Authorization"
          auth :http_basic, options, &block
        end

        def http_digest(options = {}, &block)
          options[:realm] ||= "API Authorization"
          options[:opaque] ||= "secret"
          auth :http_digest, options, &block
        end
      end
    end
  end
end
