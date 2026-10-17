# frozen_string_literal: true

module Grape
  module DSL
    module Mounting
      def given(conditional_option, &)
        return unless conditional_option

        mounted(&)
      end

      def mounted(&block)
        evaluate_as_instance_with_configuration(block, lazy: true)
      end

      def mount(mounts, opts = {})
        mount_opts = opts
        if opts[:refresh_already_mounted]
          Grape.deprecator.warn('`refresh_already_mounted` is not a `mount` option and will be ignored in a future release.')
          drop_endpoints_mounted_for(mounts)
          # Dropped before the recursion below re-enters with the same options,
          # so a Grape API does not warn once per mount and once per instance.
          mount_opts = opts.except(:refresh_already_mounted)
        end

        normalize_mounts(mounts).each_pair do |app, path|
          if app.respond_to?(:mount_instance)
            mount({ app.mount_instance(configuration: mount_opts[:with] || {}) => path }, mount_opts)
            next
          end

          endpoints << Grape::Endpoint.new(
            mounted_setting(app, path),
            http_methods: '*',
            path:,
            app:,
            anchor: false,
            api: self
          )
        end
      end

      private

      # The settings the endpoint mounting +app+ at +path+ is built with. Past
      # #mount's +mount_instance+ branch, a Grape app is an already instantiated
      # Grape::API::Instance (vs. a bare Rack app): it inherits this API's
      # settings and is built from its own.
      def mounted_setting(app, path)
        return inheritable_setting unless app.is_a?(Grape::Mountable)

        app.top_level_setting.add_mount_path(Grape::Util::PathNormalizer.call(path))
        app.inherit_settings(inheritable_setting)
        app.change!
        change!
        app.top_level_setting
      end

      # Re-mount +mounts+, replacing any endpoint already mounted for the same
      # base API rather than adding a second one. Called by
      # {Grape::API.refresh_mount_step} when a class-level method runs after the
      # API was mounted.
      #
      # A bare Rack app is put back where it was mounted. It is routed as an
      # ANY route, and those are tried in the order they were declared, so
      # re-mounting it last let a catch-all declared after it answer first. A
      # mounted Grape API still moves to the end: its routes answer for
      # specific methods, where moving them would change which of two
      # routes on the same path answers.
      def refresh_mounted_api(mounts, opts = {})
        namespace = inheritable_setting.namespace_path
        normalize_mounts(mounts).each_pair do |app, path|
          position = endpoints.index { |endpoint| mounted_at?(endpoint, app, Array(path), namespace) } unless app.respond_to?(:mount_instance)
          drop_endpoints_mounted_for(app => path)
          mount({ app => path }, opts)
          endpoints.insert(position, endpoints.pop) if position
        end
      end

      # A mounted Grape API is stored as the throwaway instance +mount+ built
      # for it, never as the class that was written, so endpoints are matched on
      # the base API both of them share -- and on where it was mounted, the
      # path and the current namespace: the same API mounted at two paths, or
      # in two namespaces, is two mounts, and refreshing one must leave the
      # other in place.
      def drop_endpoints_mounted_for(mounts)
        namespace = inheritable_setting.namespace_path
        normalize_mounts(mounts).each_pair do |app, path|
          paths = Array(path)
          endpoints.delete_if do |endpoint|
            dropped = mounted_at?(endpoint, app, paths, namespace)
            release_mount_instance(endpoint.mounted_app) if dropped
            dropped
          end
        end
      end

      # A Grape API keeps every instance +mount+ builds for it, so that steps
      # recorded later replay onto each (see Grape::API::Instance.base=). Once
      # the endpoint serving one is dropped, nothing serves it: its API lets go
      # of it, and of the instances built for the APIs mounted inside it.
      # Otherwise every refresh left another copy of each mounted API behind.
      def release_mount_instance(mounted)
        return unless mounted.respond_to?(:base) && mounted.base.respond_to?(:instances)

        mounted.base.instances.delete(mounted)
        mounted.endpoints.each { |endpoint| release_mount_instance(endpoint.mounted_app) }
      end

      # A bare app mounts at the root. The test is +Hash+ rather than
      # +respond_to?(:each_pair)+ because a Struct or an OpenStruct answers that
      # too, and neither can express an app => path mapping — their keys are
      # member names. Reading one as a mapping would silently mount nonsense
      # instead of mounting the app itself.
      def normalize_mounts(mounts)
        mounts.is_a?(Hash) ? mounts : { mounts => '/' }
      end

      def mounted_at?(endpoint, app, paths, namespace)
        same_mounted_app?(endpoint.mounted_app, app) && endpoint.path == paths && endpoint.namespace == namespace
      end

      # Two mounts refer to the same app when they share the same base Grape
      # API. +mount+ turns every mounted Grape API into a throwaway
      # +mount_instance+ (a fresh +Class.new+ per mount), so object identity
      # never holds across mounts; comparing the base is the real signal.
      # Plain Rack apps have no base and are mounted as-is, so they fall back
      # to object identity.
      def same_mounted_app?(mounted, app)
        return mounted.base.equal?(app.base) if mounted.respond_to?(:base) && app.respond_to?(:base)

        mounted.equal?(app)
      end

      def evaluate_as_instance_with_configuration(block, lazy: false)
        lazy_block = Grape::Util::Lazy::Block.new do |configuration|
          value_for_configuration = configuration
          self.configuration = value_for_configuration.evaluate if value_for_configuration.is_a?(Grape::Util::Lazy::Base)
          response = instance_eval(&block)
          self.configuration = value_for_configuration
          response
        end
        return lazy_block if @base && base_instance? && lazy

        lazy_block.evaluate_from(configuration)
      end
    end
  end
end
