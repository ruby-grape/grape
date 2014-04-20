module Grape
  module Meta
    # An object containing descriptive metadata for an
    # endpoint.
    class Description
      def initialize(summary = nil, data = {})
        @summary = summary
        @data = data
        @responses = []
        @success_response = nil
        @failure_response = {}
      end

      def detail(detail = false)
        @detail = detail if detail
        @detail = nil if detail.nil?
        @detail
      end

      def summary(summary = false)
        @summary = summary if summary
        @summary = nil if summary.nil?
        @summary
      end

      def response(entity, status, description)
        response = Response.new(entity, status, description)
        @responses << response
        response
      end

      def success(entity, status, description)
        @success_response = response(entity, status, description)
      end

      def failure(name, status, description)
        failure_response = Response.new(Grape::ErrorEntity.new(name, status, description), status, description)
        response failure_response
        @failure_responses[name.to_sym] = failure_response
      end
    end
  end
end
