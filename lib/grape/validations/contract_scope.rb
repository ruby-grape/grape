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
        declared = block ? Dry::Schema.Params(parent: contract, &block) : contract

        if declared.respond_to?(:schema)
          # It's a Dry::Validation::Contract, then.
          schema = declared.new
          key_map = schema.schema.key_map
        else
          # Dry::Schema::Processor, hopefully.
          schema = declared
          key_map = declared.key_map
        end

        api.inheritable_setting.add_contract_key_map(key_map)
        api.inheritable_setting.add_validation(Validators::ContractScopeValidator.new(schema:))
      end
    end
  end
end
