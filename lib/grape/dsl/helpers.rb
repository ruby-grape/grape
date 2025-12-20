# frozen_string_literal: true

module Grape
  module DSL
    module Helpers
      # Add helper methods that will be accessible from any
      # endpoint within this namespace (and child namespaces).
      #
      # When called without a block, all known helpers within this scope
      # are included.
      #
      # @param [Array] new_modules optional array of modules to include
      # @param [Block] block optional block of methods to include
      #
      # @example Define some helpers.
      #
      #     class ExampleAPI < Grape::API
      #       helpers do
      #         def current_user
      #           User.find_by_id(params[:token])
      #         end
      #       end
      #     end
      #
      # @example Include many modules
      #
      #     class ExampleAPI < Grape::API
      #       helpers Authentication, Mailer, OtherModule
      #     end
      #
      def helpers(*new_modules, &block)
        include_new_modules(new_modules)
        include_block(block)
        include_all_in_scope if !block && new_modules.empty?
      end

      private

      def include_new_modules(modules)
        return if modules.empty?

        modules.each { |mod| make_inclusion(mod) }
      end

      def include_block(block)
        return unless block

        Module.new.tap do |mod|
          make_inclusion(mod) { mod.class_eval(&block) }
        end
      end

      def make_inclusion(mod, &)
        define_boolean_in_mod(mod)
        inject_api_helpers_to_mod(mod, &)
        inheritable_setting.namespace_stackable[:helpers] = mod
      end

      def include_all_in_scope
        Module.new.tap do |mod|
          namespace_stackable(:helpers).each { |mod_to_include| mod.include mod_to_include }
          change!
        end
      end

      def define_boolean_in_mod(mod)
        return if defined? mod::Boolean

        mod.const_set(:Boolean, Grape::API::Boolean)
      end

      def inject_api_helpers_to_mod(mod, &block)
        mod.extend(BaseHelper) unless mod.is_a?(BaseHelper)
        yield if block
        mod.api_changed(self)
      end

      # This module extends user defined helpers
      # to provide some API-specific functionality.
      module BaseHelper
        attr_accessor :api

        def params(name, &block)
          @named_params ||= {}
          @named_params[name] = block
        end

        def api_changed(new_api)
          @api = new_api
          process_named_params
        end

        protected

        def process_named_params
          return if @named_params.blank?

          api.inheritable_setting.namespace_stackable[:named_params] = @named_params
        end
      end
    end
  end
end
