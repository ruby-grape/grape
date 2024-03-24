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

        # Declare the contract to be used for the endpoint's parameters.
        # @param contract [Class<Dry::Validation::Contract> | Dry::Schema::Processor]
        #   The contract or schema to be used for validation. Optional.
        # @yield a block yielding a new instance of Dry::Schema::Params
        #   subclass, allowing to define the schema inline. When the
        #   +contract+ parameter is a schema, it will be used as a parent. Optional.
        def contract(contract = nil, &block)
          raise ArgumentError, 'Either contract or block must be provided' unless contract || block
          raise ArgumentError, 'Cannot inherit from contract, only schema' if block && contract.respond_to?(:schema)

          Grape::Validations::ContractScope.new(self, contract, &block)
        end
      end
    end
  end
end
