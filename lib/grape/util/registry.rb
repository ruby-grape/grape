# frozen_string_literal: true

module Grape
  module Util
    module Registry
      def register(klass)
        short_name = build_short_name(klass)
        return if short_name.nil?

        warn "#{short_name} is already registered with class #{registry[short_name]}. It will be overridden globally with the following: #{klass.name}" if registry.key?(short_name)
        @registry = registry.merge(short_name => klass, short_name.to_sym => klass).freeze
      end

      private

      def build_short_name(klass)
        return if klass.name.blank?

        klass.name.demodulize.underscore
      end

      # Every registration under both spellings in one plain Hash, so a lookup
      # is a single +Hash#[]+. A +HashWithIndifferentAccess+ converted the key
      # on every read instead -- and these registries are read on the request
      # path, by +Grape::Formatter+ once per response, by +Grape::Parser+ once
      # per parsed body and by +Grape::ParamsBuilder+ once per params build,
      # always with a Symbol, which is the spelling +convert_key+ allocates a
      # String for.
      #
      # +register+ derives the short name as a String, so the Symbol is the
      # alias.
      #
      # Registration replaces the Hash instead of writing into it, and freezes
      # the replacement: a registry is written when a formatter, parser,
      # params builder, validator or versioner class is defined, and from then
      # on it is only ever looked up -- on the request path, at that. Nothing
      # holding a registry can find it changed underneath, and nothing can
      # write to one without going through +register+.
      def registry
        @registry ||= {}.freeze
      end
    end
  end
end
