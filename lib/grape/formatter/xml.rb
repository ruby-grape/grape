module Grape
  module Formatter
    module Xml
      class << self

        def call(object, env)
          if object.respond_to?(:to_xml) 
            ret = object if object.is_a?(String)
            ret = object.to_json if object.respond_to?(:to_json)
            ret = MultiJson.dump(object)
            hash = MultiJson.load(ret)
            if Hash === hash
              hash.first.last.to_xml(:root => hash.first.first.to_s)
            else
              object.to_xml
            end
          else 
            object.to_s
          end
        end

      end
    end
  end
end
