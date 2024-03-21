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

        api.namespace_stackable(:contract_key_map, key_map)

        validator_options = {
          validator_class: Validator,
          opts: { schema: contract }
        }

        api.namespace_stackable(:validations, validator_options)
      end

      class Validator
        attr_reader :schema

        def initialize(*_args, schema:)
          @schema = schema
        end

        # Validates a given request.
        # @param request [Grape::Request] the request currently being handled
        # @raise [Grape::Exceptions::ValidationArrayErrors] if validation failed
        # @return [void]
        def validate(request)
          res = schema.call(request.params)

          if res.success?
            request.params.deep_merge!(res.to_h)
            return
          end

          errors = []

          res.errors.messages.each do |message|
            full_name = message.path.first.to_s

            full_name += "[#{message.path[1..].join('][')}]" if message.path.size > 1

            errors << Grape::Exceptions::Validation.new(params: [full_name], message: message.text)
          end

          raise Grape::Exceptions::ValidationArrayErrors.new(errors)
        end

        def fail_fast?
          false
        end
      end
    end
  end
end
