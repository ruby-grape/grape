# frozen_string_literal: true

module Grape
  module Validations
    module Validators
      class ContractScopeValidator < Base
        attr_reader :schema

        def initialize(_attrs, _options, _required, _scope, opts)
          super
          @schema = opts.fetch(:schema)
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

          raise Grape::Exceptions::ValidationArrayErrors.new(build_errors_from_messages(res.errors.messages))
        end

        private

        def build_errors_from_messages(messages)
          messages.map do |message|
            full_name = message.path.first.to_s
            full_name << "[#{message.path[1..].join('][')}]" if message.path.size > 1
            Grape::Exceptions::Validation.new(params: [full_name], message: message.text)
          end
        end
      end
    end
  end
end
