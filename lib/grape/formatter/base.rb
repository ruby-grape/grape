# frozen_string_literal: true

module Grape
  module Formatter
    class Base
      def self.call(_object, _env)
        raise NotImplementedError
      end

      def self.inherited(klass)
        super
        return if klass.name.blank?

        Formatter.register(klass.name.demodulize.underscore, klass)
      end
    end
  end
end
