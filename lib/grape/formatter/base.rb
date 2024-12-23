# frozen_string_literal: true

module Grape
  module Formatter
    class Base
      def self.call(_object, _env)
        raise NotImplementedError
      end

      def self.inherited(klass)
        super
        Formatter.register(klass)
      end
    end
  end
end
