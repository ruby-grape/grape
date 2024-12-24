# frozen_string_literal: true

module Grape
  module Parser
    class Base
      def self.call(_object, _env)
        raise NotImplementedError
      end

      def self.inherited(klass)
        super
        Parser.register(klass)
      end
    end
  end
end
