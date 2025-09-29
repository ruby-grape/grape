# frozen_string_literal: true

module Grape
  module Validations
    class ContractScope
      # Declare the contract to be used for the endpoint's parameters.
      # @param api [API] the API endpoint to modify.
      # @param contract the contract or schema to be used for validation. Optional.
      # @yield a block yielding a new schema class. Optional.
      def initialize(api, contract = nil, &block)
        # When block is passed, the first arg is either schema or nil.
        contract = Dry::Schema.Params(parent: contract, &block) if block

        if contract.respond_to?(:schema)
          # It's a Dry::Validation::Contract, then.
          contract = contract.new
          key_map = contract.schema.key_map
        else
          # Dry::Schema::Processor, hopefully.
          key_map = contract.key_map
        end

        api.inheritable_setting.namespace_stackable[:contract_key_map] = key_map

        validator_options = {
          validator_class: Grape::Validations.require_validator(:contract_scope),
          opts: { schema: contract, fail_fast: false }
        }

        api.inheritable_setting.namespace_stackable[:validations] = validator_options
      end
    end
  end
end
