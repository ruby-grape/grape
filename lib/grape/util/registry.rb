# frozen_string_literal: true

module Grape
  module Util
    module Registry
      def register(short_name, klass)
        warn "#{short_name} is already registered with class #{klass}" if registry.key?(short_name)
        registry[short_name] = klass
      end

      private

      def registry
        @registry ||= {}.with_indifferent_access
      end
    end
  end
end
