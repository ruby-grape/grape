module Grape
  module Formatter
    module Json
      class << self
        if object.respond_to?(:to_json)
          obj = object.to_json
          JSON.pretty_generate(JSON.parse(obj))
        else
          obj = MultiJson.dump(object)
          JSON.pretty_generate(JSON.parse(obj))
        end
      end
    end
  end
end
