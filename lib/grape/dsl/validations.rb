# frozen_string_literal: true

module Grape
  module DSL
    module Validations
      # Opens a root-level ParamsScope, defining parameter coercions and
      # validations for the endpoint.
      # @yield instance context of the new scope
      def params(&)
        Grape::Validations::ParamsScope.new(api: self, type: Hash, &)
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

      private

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
        inheritable_setting.namespace_stackable.delete(:declared_params, :params, :validations)
      end
    end
  end
end
