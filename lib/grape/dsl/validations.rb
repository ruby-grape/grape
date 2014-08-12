require 'active_support/concern'

module Grape
  module DSL
    module Validations
      extend ActiveSupport::Concern

      included do

      end

      module ClassMethods
        def reset_validations!
          settings.peek[:declared_params] = []
          settings.peek[:validations] = []
        end

        def params(&block)
          Grape::Validations::ParamsScope.new(api: self, type: Hash, &block)
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
