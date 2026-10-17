# frozen_string_literal: true

module Grape
  module DSL
    module Versioning
      # Called without a value, answers whether the API cascades: the value
      # given here, else the +cascade:+ of +version+, else true. The compiled
      # API reads it here too; this reader used to skip +version+, and so
      # answered true for an API that did not cascade.
      def cascade(value = nil)
        return inheritable_setting.cascade = value unless value.nil?

        setting = inheritable_setting
        return setting.cascade if setting.cascade_defined?
        return setting.version_options.cascade if setting.version_options

        true
      end

      # Specify an API version.
      #
      # Called without arguments, returns the most recently declared version
      # (or +nil+). Called with one or more version strings, registers them
      # and stores a {Grape::DSL::VersionOptions} value object on the
      # inheritable settings; when given a block, the registration applies
      # within a nested namespace.
      #
      # @example API with legacy support.
      #   class MyAPI < Grape::API
      #     version 'v2'
      #
      #     get '/main' do
      #       {some: 'data'}
      #     end
      #
      #     version 'v1' do
      #       get '/main' do
      #         {legacy: 'data'}
      #       end
      #     end
      #   end
      #
      # @param args [Array<String, Symbol>] one or more version identifiers.
      # @param using [Symbol] versioning strategy — one of +:path+ (default),
      #   +:header+, +:param+, or +:accept_version_header+.
      # @param cascade [Boolean] forward to subsequent routes via the
      #   +X-Cascade+ header on version mismatch. Defaults to +true+.
      # @param parameter [String] name of the query/body parameter that
      #   carries the version when +using: :param+. Defaults to +'apiver'+.
      # @param strict [Boolean] reject requests that don't supply a usable
      #   version (header strategies). Defaults to +false+.
      # @param vendor [String, nil] vendor segment for the +:header+
      #   strategy (+application/vnd.<vendor>-<version>+); required when
      #   +using: :header+.
      # @yield optional block to scope routes under this version.
      # @return [String, nil] the most recently declared version.
      # @raise [Grape::Exceptions::MissingVendorOption] when +using: :header+
      #   is supplied without a +:vendor+.
      def version(*args, using: :path, cascade: true, parameter: 'apiver', strict: false, vendor: nil, &block)
        return @versions&.last if args.empty?

        options = build_version_options(using:, cascade:, parameter:, strict:, vendor:)
        requested_versions = args.flatten.map(&:to_s)

        @versions = versions | requested_versions

        if block
          within_namespace do
            apply_version(requested_versions, options)
            instance_eval(&block)
          end
        else
          apply_version(requested_versions, options)
        end

        @versions.last
      end

      # @return array of defined versions
      def versions
        @versions ||= []
      end

      private

      def build_version_options(using:, vendor:, **)
        raise Grape::Exceptions::MissingVendorOption.new if using == :header && vendor.nil?

        VersionOptions.new(using:, vendor:, **)
      end

      def apply_version(versions, options)
        inheritable_setting.version = versions
        inheritable_setting.version_options = options
      end
    end
  end
end
