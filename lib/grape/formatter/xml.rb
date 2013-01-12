module Grape
  module Formatter
    module Xml
      class << self

        def call(object, env)
          return object.to_xml if object.respond_to?(:to_xml)
          raise "cannot convert #{object.class} to xml"
        end

      end
    end
  end
end
