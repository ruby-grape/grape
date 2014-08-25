require 'active_support/concern'

module Grape
  module DSL
    module Validations
      extend ActiveSupport::Concern

      module ClassMethods
        def reset_validations!
          settings.peek[:declared_params] = []
          settings.peek[:validations] = []
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
          @last_description ||= {}
          @last_description[:params] ||= {}
          Array(names).each do |name|
            @last_description[:params][name[:full_name].to_s] ||= {}
            @last_description[:params][name[:full_name].to_s].merge!(opts)
          end
        end
      end
    end
  end
end
