require 'active_support/concern'

module Grape
  module DSL
    module Validations
      extend ActiveSupport::Concern

      include Grape::DSL::Configuration

      module ClassMethods
        def reset_validations!
          unset_namespace_stackable :declared_params
          unset_namespace_stackable :validations
          unset_namespace_stackable :params
        end

        def params(&block)
          Grape::Validations::ParamsScope.new(api: self, type: Hash, &block)
        end

        def shared_params(name, &block)
          if block_given?
            Grape::SharedParams.shared_params[name] ||= Module.new do
              extend Grape::SharedParams
            end
            Grape::SharedParams.shared_params[name].class_eval(&block)
          else
            Grape::SharedParams.shared_params[name]
          end
        end

        def include_params(*names_or_modules)
          names_or_modules.each do |name_or_module|
            mod = shared_params(name_or_module) unless name_or_module.respond_to? :api_changed
            mod = name_or_module unless mod
            mod.api_changed(self)
          end
        end

        def document_attribute(names, opts)
          route_setting(:description, {}) unless route_setting(:description)

          route_setting(:description)[:params] ||= {}

          setting = route_setting(:description)[:params]
          Array(names).each do |name|
            setting[name[:full_name].to_s] ||= {}
            setting[name[:full_name].to_s].merge!(opts)

            namespace_stackable(:params, name[:full_name].to_s => opts)
          end
        end
      end
    end
  end
end
