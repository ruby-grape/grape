module Grape
  module Formatter
    module SerializableHash
      class << self

        def call(object, env)
          return object if object.is_a?(String)
          return MultiJson.dump(serialize(object)) if serializable?(object)
          return object.to_json if object.respond_to?(:to_json)
          MultiJson.dump(object)
        end

        private

          def serializable?(object)
            object.respond_to?(:serializable_hash) || object.kind_of?(Array) && !object.map { |o| o.respond_to? :serializable_hash }.include?(false) || object.kind_of?(Hash)
          end

          def serialize(object)
            if object.respond_to? :serializable_hash
              object.serializable_hash
            elsif object.kind_of?(Array) && !object.map { |o| o.respond_to? :serializable_hash }.include?(false)
              object.map { |o| o.serializable_hash }
            elsif object.kind_of?(Hash)
              object.inject({}) do |h, (k, v)|
                h[k] = serialize(v)
                h
              end
            else
              object
            end
          end
      end
    end
  end
end
