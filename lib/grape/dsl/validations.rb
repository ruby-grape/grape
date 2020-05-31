# frozen_string_literal: true

require 'active_support/concern'

module Grape
  module DSL
    module Validations
      extend ActiveSupport::Concern

      include Grape::DSL::Configuration

      module ClassMethods
        # Clears all defined parameters and validations. The main purpose of it is to clean up
        # settings, so next endpoint won't interfere with previous one.
        #
        #    params do
        #      # params for the endpoint below this block
        #    end
        #    post '/current' do
        #      # whatever
        #    end
        #
        #    # somewhere between them the reset_validations! method gets called
        #
        #    params do
        #      # params for the endpoint below this block
        #    end
        #    post '/next' do
        #      # whatever
        #    end
        def reset_validations!
          unset_namespace_stackable :declared_params
          unset_namespace_stackable :validations
          unset_namespace_stackable :params
          unset_description_field :params
        end

        # Opens a root-level ParamsScope, defining parameter coercions and
        # validations for the endpoint.
        # @yield instance context of the new scope
        def params(&block)
          Grape::Validations::ParamsScope.new(api: self, type: Hash, &block)
        end

        def document_attribute(names, opts)
          setting = description_field(:params)
          setting ||= description_field(:params, {})
          Array(names).each do |name|
            full_name = name[:full_name].to_s
            setting[full_name] ||= {}
            setting[full_name].merge!(opts)

            namespace_stackable(:params, full_name => opts)
          end
        end
      end
    end
  end
end
