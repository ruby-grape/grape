module Grape
  module Formatter
    module Json
      class << self
        def call(object, _env)
          return object.to_json if object.respond_to?(:to_json)
          JSON.dump(object)
        end
      end
    end
  end
end
