# frozen_string_literal: true

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
        end

        # Opens a root-level ParamsScope, defining parameter coercions and
        # validations for the endpoint.
        # @yield instance context of the new scope
        def params(&block)
          Grape::Validations::ParamsScope.new(api: self, type: Hash, &block)
        end
      end
    end
  end
end
