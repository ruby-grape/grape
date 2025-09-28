# frozen_string_literal: true

module Grape
  module DSL
    module Middleware
      # Apply a custom middleware to the API. Applies
      # to the current namespace and any children, but
      # not parents.
      #
      # @param middleware_class [Class] The class of the middleware you'd like
      #   to inject.
      def use(middleware_class, *args, &block)
        arr = [:use, middleware_class, *args]
        arr << block if block

        inheritable_setting.namespace_stackable[:middleware] = arr
      end

      %i[insert insert_before insert_after].each do |method_name|
        define_method method_name do |*args, &block|
          arr = [method_name, *args]
          arr << block if block

          inheritable_setting.namespace_stackable[:middleware] = arr
        end
      end

      # Retrieve an array of the middleware classes
      # and arguments that are currently applied to the
      # application.
      def middleware
        inheritable_setting.namespace_stackable[:middleware] || []
      end
    end
  end
end
