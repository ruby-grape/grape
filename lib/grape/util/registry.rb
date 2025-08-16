# frozen_string_literal: true

module Grape
  module Util
    module Registry
      def register(klass)
        short_name = build_short_name(klass)
        return if short_name.nil?

        warn "#{short_name} is already registered with class #{registry[short_name]}. It will be overridden globally with the following: #{klass.name}" if registry.key?(short_name)
        registry[short_name] = klass
      end

      private

      def build_short_name(klass)
        return if klass.name.blank?

        klass.name.demodulize.underscore
      end

      def registry
        @registry ||= {}.with_indifferent_access
      end
    end
  end
end
