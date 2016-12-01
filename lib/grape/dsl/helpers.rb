require 'active_support/concern'

module Grape
  module DSL
    module Helpers
      extend ActiveSupport::Concern
      include Grape::DSL::Configuration

      module ClassMethods
        # Add helper methods that will be accessible from any
        # endpoint within this namespace (and child namespaces).
        #
        # When called without a block, all known helpers within this scope
        # are included.
        #
        # @param [Module] new_mod optional module of methods to include
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
        def helpers(new_mod = nil, &block)
          mod = Module.new
          if block_given? || new_mod
            if new_mod
              define_boolean_in_mod new_mod
              inject_api_helpers_to_mod new_mod
              mod.send :include, new_mod
            end

            define_boolean_in_mod(mod)
            inject_api_helpers_to_mod(mod) do
              mod.class_eval(&block)
            end if block_given?

            namespace_stackable(:helpers, mod)
          else
            namespace_stackable(:helpers).each do |mod_to_include|
              mod.send :include, mod_to_include
            end
            change!
            mod
          end
        end

        protected

        def define_boolean_in_mod(mod)
          return if defined? mod::Boolean
          mod.const_set('Boolean', Virtus::Attribute::Boolean)
        end

        def inject_api_helpers_to_mod(mod, &_block)
          mod.extend(BaseHelper) unless mod.is_a?(BaseHelper)
          yield if block_given?
          mod.api_changed(self)
        end
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
          return unless @named_params && @named_params.any?
          api.namespace_stackable(:named_params, @named_params)
        end
      end
    end
  end
end
