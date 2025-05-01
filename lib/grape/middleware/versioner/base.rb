# frozen_string_literal: true

module Grape
  module Middleware
    module Versioner
      class Base < Grape::Middleware::Base
        DEFAULT_OPTIONS = {
          pattern: /.*/i.freeze,
          version_options: {
            strict: false,
            cascade: true,
            parameter: 'apiver'
          }.freeze
        }.freeze

        def self.inherited(klass)
          super
          Versioner.register(klass)
        end

        def versions
          options[:versions]
        end

        def prefix
          options[:prefix]
        end

        def mount_path
          options[:mount_path]
        end

        def pattern
          options[:pattern]
        end

        def version_options
          options[:version_options]
        end

        def strict?
          version_options[:strict]
        end

        # By default those errors contain an `X-Cascade` header set to `pass`, which allows nesting and stacking
        # of routes (see Grape::Router) for more information). To prevent
        # this behavior, and not add the `X-Cascade` header, one can set the `:cascade` option to `false`.
        def cascade?
          version_options[:cascade]
        end

        def parameter_key
          version_options[:parameter]
        end

        def vendor
          version_options[:vendor]
        end

        def error_headers
          cascade? ? { 'X-Cascade' => 'pass' } : {}
        end

        def potential_version_match?(potential_version)
          versions.blank? || versions.any? { |v| v.to_s == potential_version }
        end

        def version_not_found!
          throw :error, status: 404, message: '404 API Version Not Found', headers: { 'X-Cascade' => 'pass' }
        end
      end
    end
  end
end
