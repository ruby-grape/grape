# frozen_string_literal: true

module Grape
  module Middleware
    module Auth
      module DSL
        def auth(type = nil, *legacy_options, **options, &block)
          namespace_inheritable = inheritable_setting.namespace_inheritable
          return namespace_inheritable[:auth] unless type

          options = merge_legacy_auth_options(:auth, legacy_options, options)
          namespace_inheritable[:auth] = { type: type.to_sym, proc: block }.merge!(options)
          use Grape::Middleware::Auth::Base, namespace_inheritable[:auth]
        end

        # Add HTTP Basic authorization to the API.
        #
        # @param options [Hash] a hash of options
        # @option options [String] :realm "API Authorization" the HTTP Basic realm
        def http_basic(*legacy_options, **options, &)
          options = merge_legacy_auth_options(:http_basic, legacy_options, options)
          options[:realm] ||= 'API Authorization'
          auth(:http_basic, **options, &)
        end

        def http_digest(*legacy_options, **options, &)
          options = merge_legacy_auth_options(:http_digest, legacy_options, options)
          options[:realm] ||= 'API Authorization'

          if options[:realm].respond_to?(:values_at)
            options[:realm][:opaque] ||= 'secret'
          else
            options[:opaque] ||= 'secret'
          end

          auth(:http_digest, **options, &)
        end

        private

        # @deprecated Passing a positional options Hash is deprecated; pass
        #   keyword arguments instead. Kept so downstream callers keep working
        #   through the deprecation cycle.
        def merge_legacy_auth_options(method_name, legacy_options, options)
          return options if legacy_options.empty?

          Grape.deprecator.warn("Passing a positional options Hash to `#{method_name}` is deprecated. Pass keyword arguments instead.")
          legacy_options.first.merge(options)
        end
      end
    end
  end
end
