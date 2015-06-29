module Grape
  module NamedRoutes
    class MissedRequiredParam < StandardError
      attr_reader :missed_param

      def initialize(param)
        @missed_param = param
      end
    end
  end
end
