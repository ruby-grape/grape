# frozen_string_literal: true

module Grape
  module Formatter
    class SerializableHash < Base
      class << self
        def call(object, _env)
          return object if object.is_a?(String)
          return ::Grape::Json.dump(serialize(object)) if serializable?(object)

          ::Grape::Json.dump(object)
        end

        private

        def serializable?(object)
          object.respond_to?(:serializable_hash) || array_serializable?(object) || object.is_a?(Hash)
        end

        def serialize(object)
          return object.serializable_hash if object.respond_to?(:serializable_hash)
          return object.map(&:serializable_hash) if array_serializable?(object)
          return object.transform_values { |v| serialize(v) } if object.is_a?(Hash)

          object
        end

        def array_serializable?(object)
          object.is_a?(Array) && object.all? { |o| o.respond_to? :serializable_hash }
        end
      end
    end
  end
end
