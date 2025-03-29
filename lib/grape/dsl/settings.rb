# frozen_string_literal: true

module Grape
  module DSL
    # Keeps track of settings (implemented as key-value pairs, grouped by
    # types), in two contexts: top-level settings which apply globally no
    # matter where they're defined, and inheritable settings which apply only
    # in the current scope and scopes nested under it.
    module Settings
      extend Forwardable

      attr_writer :inheritable_setting, :top_level_setting

      def_delegators :inheritable_setting, :route_end

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

      # @param type [Symbol]
      # @param key [Symbol]
      def unset(type, key)
        setting = inheritable_setting.send(type)
        setting.delete key
      end

      # @param type [Symbol]
      # @param key [Symbol]
      # @param value [Object] will be stored if the value is currently empty
      # @return either the old value, if it wasn't nil, or the given value
      def get_or_set(type, key, value)
        setting = inheritable_setting.send(type)
        if value.nil?
          setting[key]
        else
          setting[key] = value
        end
      end

      # defines the following methods:
      # - namespace_inheritable
      # - namespace_stackable

      %i[namespace_inheritable namespace_stackable].each do |method_name|
        define_method method_name do |key, value = nil|
          get_or_set method_name, key, value
        end
      end

      def unset_namespace_stackable(*keys)
        keys.each do |key|
          unset :namespace_stackable, key
        end
      end

      # defines the following methods:
      # - global_setting
      # - route_setting
      # - namespace_setting

      %i[global route namespace].each do |method_name|
        define_method :"#{method_name}_setting" do |key, value = nil|
          get_or_set method_name, key, value
        end
      end

      # @param key [Symbol]
      def namespace_inheritable_to_nil(key)
        inheritable_setting.namespace_inheritable[key] = nil
      end

      def namespace_reverse_stackable(key, value = nil)
        get_or_set :namespace_reverse_stackable, key, value
      end

      def namespace_stackable_with_hash(key)
        settings = get_or_set :namespace_stackable, key, nil
        return if settings.blank?

        settings.each_with_object({}) { |value, result| result.deep_merge!(value) }
      end

      def namespace_reverse_stackable_with_hash(key)
        settings = get_or_set :namespace_reverse_stackable, key, nil
        return if settings.blank?

        settings.each_with_object({}) do |setting, result|
          result.merge!(setting) { |_k, s1, _s2| s1 }
        end
      end

      # Fork our inheritable settings to a new instance, copied from our
      # parent's, but separate so we won't modify it. Every call to this
      # method should have an answering call to #namespace_end.
      def namespace_start
        @inheritable_setting = Grape::Util::InheritableSetting.new.tap { |new_settings| new_settings.inherit_from inheritable_setting }
      end

      # Set the inheritable settings pointer back up by one level.
      def namespace_end
        route_end
        @inheritable_setting = inheritable_setting.parent
      end

      # Execute the block within a context where our inheritable settings are forked
      # to a new copy (see #namespace_start).
      def within_namespace(&block)
        namespace_start

        result = yield if block

        namespace_end
        reset_validations!

        result
      end
    end
  end
end
