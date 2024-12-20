# frozen_string_literal: true

module Grape
  module Parser
    class Base
      def self.call(_object, _env)
        raise NotImplementedError
      end

      def self.inherited(klass)
        super
        return if klass.name.blank?

        short_name = klass.name.demodulize.underscore
        Parser.register(short_name, klass)
      end
    end
  end
end
