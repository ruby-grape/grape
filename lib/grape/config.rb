module Grape
  module Config
    module SettingStore
      def setting(setting_name, opts = {})
        @setting_caller ||= {}.with_indifferent_access
        default_caller = opts[:default] || -> { nil }
        @setting_caller[setting_name] = { default: default_caller }
      end

      def [](setting_name)
        callers = @setting_caller[setting_name]
        (callers[:configured] || callers[:default]).call
      end

      def []=(setting_name, value)
        @setting_caller[setting_name][:configured] = -> { value }
      end
    end
    # A singleton setup module
    extend SettingStore

    setting :param_builder, default: -> { Grape::Extensions::ActiveSupport::HashWithIndifferentAccess::ParamBuilder }
  end
end
