module Grape
  module Formatter
    module Json
      class << self

        def call(object, env)
          return object if object.is_a?(String)
          return object.to_json if object.respond_to?(:to_json)
          MultiJson.dump(object)
        end

      end
    end
  end
end
