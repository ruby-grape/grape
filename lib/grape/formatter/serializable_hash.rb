# frozen_string_literal: true

module Grape
  module Formatter
    class SerializableHash < Base
      class << self
        def call(object, _env)
          return object if object.is_a?(String)
          return ::Grape::Json.dump(serialize(object)) if serializable?(object)
          return object.to_json if object.respond_to?(:to_json)

          ::Grape::Json.dump(object)
        end

        private

        def serializable?(object)
          object.respond_to?(:serializable_hash) || array_serializable?(object) || object.is_a?(Hash)
        end

        def serialize(object)
          if object.respond_to? :serializable_hash
            object.serializable_hash
          elsif array_serializable?(object)
            object.map(&:serializable_hash)
          elsif object.is_a?(Hash)
            object.transform_values { |v| serialize(v) }
          else
            object
          end
        end

        def array_serializable?(object)
          object.is_a?(Array) && object.all? { |o| o.respond_to? :serializable_hash }
        end
      end
    end
  end
end
