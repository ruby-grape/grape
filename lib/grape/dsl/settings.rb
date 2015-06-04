require 'active_support/concern'

module Grape
  module DSL
    module Settings
      extend ActiveSupport::Concern

      attr_accessor :inheritable_setting, :top_level_setting

      def top_level_setting
        @top_level_setting ||= Grape::Util::InheritableSetting.new
      end

      def inheritable_setting
        @inheritable_setting ||= Grape::Util::InheritableSetting.new.tap { |new_settings| new_settings.inherit_from top_level_setting }
      end

      def unset(type, key)
        setting = inheritable_setting.send(type)
        setting.delete key
      end

      def get_or_set(type, key, value)
        setting = inheritable_setting.send(type)
        if value.nil?
          setting[key]
        else
          setting[key] = value
        end
      end

      def global_setting(key, value = nil)
        get_or_set :global, key, value
      end

      def unset_global_setting(key)
        unset :global, key
      end

      def route_setting(key, value = nil)
        get_or_set :route, key, value
      end

      def unset_route_setting(key)
        unset :route, key
      end

      def namespace_setting(key, value = nil)
        get_or_set :namespace, key, value
      end

      def unset_namespace_setting(key)
        unset :namespace_setting, key
      end

      def namespace_inheritable(key, value = nil)
        get_or_set :namespace_inheritable, key, value
      end

      def unset_namespace_inheritable(key)
        unset :namespace_inheritable, key
      end

      def namespace_inheritable_to_nil(key)
        inheritable_setting.namespace_inheritable[key] = nil
      end

      def namespace_stackable(key, value = nil)
        get_or_set :namespace_stackable, key, value
      end

      def unset_namespace_stackable(key)
        unset :namespace_stackable, key
      end

      def api_class_setting(key, value = nil)
        get_or_set :api_class, key, value
      end

      def unset_api_class_setting(key)
        unset :api_class_setting, key
      end

      def namespace_start
        @inheritable_setting = Grape::Util::InheritableSetting.new.tap { |new_settings| new_settings.inherit_from inheritable_setting }
      end

      def namespace_end
        route_end
        @inheritable_setting = inheritable_setting.parent
      end

      def route_end
        inheritable_setting.route_end
        reset_validations!
      end

      def within_namespace(&_block)
        namespace_start

        result = yield if block_given?

        namespace_end
        reset_validations!

        result
      end
    end
  end
end
