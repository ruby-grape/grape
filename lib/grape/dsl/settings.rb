# frozen_string_literal: true

module Grape
  module DSL
    # Keeps track of settings (implemented as key-value pairs, grouped by
    # types), in two contexts: top-level settings which apply globally no
    # matter where they're defined, and inheritable settings which apply only
    # in the current scope and scopes nested under it.
    module Settings
      attr_writer :inheritable_setting

      # Fetch our top-level settings, which apply to all endpoints in the API.
      def top_level_setting
        @top_level_setting ||= Grape::Util::InheritableSetting.new.tap do |setting|
          # Doesn't try to inherit settings from +Grape::API::Instance+ which also responds to
          # +inheritable_setting+, however, it doesn't contain any user-defined settings.
          # Otherwise, it would lead to an extra instance of +Grape::Util::InheritableSetting+
          # in the chain for every endpoint.
          setting.inherit_from superclass.inheritable_setting if defined?(superclass) && superclass.respond_to?(:inheritable_setting) && superclass != Grape::API::Instance
        end
      end

      # Fetch our current inheritable settings, which are inherited by
      # nested scopes but not shared across siblings.
      def inheritable_setting
        @inheritable_setting ||= Grape::Util::InheritableSetting.new.tap { |new_settings| new_settings.inherit_from top_level_setting }
      end

      def global_setting(key, value = nil)
        get_or_set(inheritable_setting.global, key, value)
      end

      def route_setting(key, value = nil)
        get_or_set(inheritable_setting.route, key, value)
      end

      def namespace_setting(key, value = nil)
        get_or_set(inheritable_setting.namespace, key, value)
      end

      private

      # Execute the block within a context where our inheritable settings are forked
      # to a new copy (see #namespace_start).
      def within_namespace
        new_inheritable_settings = Grape::Util::InheritableSetting.new
        new_inheritable_settings.inherit_from inheritable_setting

        @inheritable_setting = new_inheritable_settings

        result = yield

        inheritable_setting.route_end
        @inheritable_setting = inheritable_setting.parent
        reset_validations!

        result
      end

      def get_or_set(setting, key, value)
        return setting[key] if value.nil?

        setting[key] = value
      end
    end
  end
end
