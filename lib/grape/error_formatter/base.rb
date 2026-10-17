# frozen_string_literal: true

module Grape
  module ErrorFormatter
    class Base
      class << self
        # Custom error formatters override +call+. The +error+ is a frozen
        # {Grape::Exceptions::ErrorResponse} carrying +status+/+message+/
        # +headers+/+backtrace+/+original_exception+. +env+ is the Rack env
        # (needed by entity-presenter resolution). +include_backtrace+ and
        # +include_original_exception+ are the request-time toggles set by
        # +rescue_from+; the base implementation embeds the corresponding
        # fields in the response body when they are true.
        def call(error:, env: nil, include_backtrace: false, include_original_exception: false)
          wrapped_message = wrap_message(present(error.message, env))
          if wrapped_message.is_a?(Hash)
            wrapped_message[:backtrace] = error.backtrace if include_backtrace && error.backtrace.present?
            wrapped_message[:original_exception] = error.original_exception.inspect if include_original_exception && error.original_exception
          end

          format_structured_message(wrapped_message)
        end

        def present(message, env)
          # error! accepts a message hash with an optional :with key specifying the entity presenter.
          # Extract it here so the presenter can be resolved and the key is not serialized in the response.
          # See spec/integration/grape_entity/entity_spec.rb for examples.
          with = nil
          payload = message
          if message.is_a?(Hash) && message.key?(:with)
            payload = message.dup
            with = payload.delete(:with)
          end

          presenter = with || env[Grape::Env::API_ENDPOINT].entity_class_for_obj(payload) || failure_presenter(payload, env)
          return payload unless presenter

          embeds = { env: }
          embeds[:version] = env[Grape::Env::API_VERSION] if env.key?(Grape::Env::API_VERSION)
          presenter.represent(payload, embeds).serializable_hash
        end

        def wrap_message(message)
          return message if message.is_a?(Hash)

          { message: }
        end

        def format_structured_message(_structured_message)
          raise NotImplementedError
        end

        private

        # The entity the route's failure codes name for the status being
        # answered: those entities document a structured error body.
        #
        # A String message has no attributes for one to expose -- presenting
        # it raised, and the failsafe answered 500 in place of the status
        # +error!+ asked for -- so it is left for #wrap_message. And a route's
        # failure presenters are written for the errors the endpoint itself
        # raises: one raised by middleware before the endpoint ran -- it has
        # no request yet -- keeps the shape that middleware gave it rather than
        # being fit to an entity it was not written for.
        def failure_presenter(payload, env)
          return if payload.is_a?(String)

          routing_args = env[Grape::Env::GRAPE_ROUTING_ARGS]
          endpoint = env[Grape::Env::API_ENDPOINT]
          return if routing_args.nil? || !endpoint.request

          found_code = Array(routing_args[:route_info].failure).find { |http_code| http_code[0].to_i == endpoint.status && http_code[2].respond_to?(:represent) }
          found_code[2] if found_code
        end

        def inherited(klass)
          super
          ErrorFormatter.register(klass)
        end
      end
    end
  end
end
