# frozen_string_literal: true

module Grape
  module Middleware
    module Auth
      module DSL
        def auth(type = nil, options = {}, &block)
          namespace_inheritable = inheritable_setting.namespace_inheritable
          return namespace_inheritable[:auth] unless type

          namespace_inheritable[:auth] = options.reverse_merge(type: type.to_sym, proc: block)
          use Grape::Middleware::Auth::Base, namespace_inheritable[:auth]
        end

        # Add HTTP Basic authorization to the API.
        #
        # @param [Hash] options A hash of options.
        # @option options [String] :realm "API Authorization" The HTTP Basic realm.
        def http_basic(options = {}, &)
          options[:realm] ||= 'API Authorization'
          auth(:http_basic, options, &)
        end

        def http_digest(options = {}, &)
          options[:realm] ||= 'API Authorization'

          if options[:realm].respond_to?(:values_at)
            options[:realm][:opaque] ||= 'secret'
          else
            options[:opaque] ||= 'secret'
          end

          auth(:http_digest, options, &)
        end
      end
    end
  end
end
